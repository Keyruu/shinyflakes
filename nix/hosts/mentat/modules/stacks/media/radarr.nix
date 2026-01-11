{ config, ... }:
let
  radarrPath = "/etc/stacks/radarr";
  my = config.services.my.radarr;
in
{
  systemd.tmpfiles.rules = [
    "d ${radarrPath}/config 0755 root root"
  ];

  services.my.radarr = {
    port = 7878;
    domain = "radarr.lab.keyruu.de";
  };

  virtualisation.quadlet.containers = {
    media-radarr = {
      containerConfig = {
        image = "ghcr.io/hotio/radarr:release-6.0.4.10291";
        environments = {
          PUID = "0";
          PGID = "0";
          UMASK = "022";
          TZ = "Europe/Berlin";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${radarrPath}/config:/config"
          "/main/media:/data"
        ];
        networks = [
          "media-gluetun.container"
        ];
      };
      serviceConfig = {
        Restart = "always";
      };
      unitConfig = {
        After = [ "media-gluetun.service" ];
        Requires = [ "media-gluetun.service" ];
      };
    };
    media-gluetun.containerConfig.publishPorts = [
      "127.0.0.1:${toString my.port}:7878"
    ];
  };

  services.nginx.virtualHosts = {
    "${my.domain}" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString my.port}";
        proxyWebsockets = true;
      };
    };
  };
}

