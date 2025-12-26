_:
let
  sabnzbdPath = "/etc/stacks/sabnzbd";
in
{
  systemd.tmpfiles.rules = [
    "d ${sabnzbdPath}/config 0755 root root"
  ];

  virtualisation.quadlet.containers = {
    torrent-sabnzbd = {
      containerConfig = {
        image = "lscr.io/linuxserver/sabnzbd:4.5.5";
        environments = {
          PUID = "0";
          PGID = "0";
          TZ = "Europe/Berlin";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${sabnzbdPath}/config:/config"
          "/main/media/downloads:/data/downloads"
        ];
        networks = [
          "torrent-gluetun.container"
        ];
      };
      serviceConfig = {
        Restart = "always";
      };
      unitConfig = {
        After = [ "torrent-gluetun.service" ];
        Requires = [ "torrent-gluetun.service" ];
      };
    };
    torrent-gluetun.containerConfig.publishPorts = [
      "127.0.0.1:8081:8080"
    ];
  };

  services.nginx.virtualHosts = {
    "sabnzbd.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8081";
        proxyWebsockets = true;
      };
    };
  };
}
