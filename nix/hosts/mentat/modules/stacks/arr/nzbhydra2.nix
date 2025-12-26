_:
let
  nzbhydra2 = "/etc/stacks/nzbhydra2";
in
{
  systemd.tmpfiles.rules = [
    "d ${nzbhydra2}/config 0755 root root"
  ];

  virtualisation.quadlet.containers = {
    torrent-nzbhydra2 = {
      containerConfig = {
        image = "lscr.io/linuxserver/nzbhydra2:8.1.2";
        environments = {
          PUID = "0";
          PGID = "0";
          TZ = "Europe/Berlin";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${nzbhydra2}/config:/config"
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
      "127.0.0.1:5076:5076"
    ];
  };

  services.nginx.virtualHosts = {
    "nzbhydra2.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:5076";
        proxyWebsockets = true;
      };
    };
  };
}
