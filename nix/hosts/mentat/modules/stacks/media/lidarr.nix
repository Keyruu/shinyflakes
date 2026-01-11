{ config, ... }:
let
  lidarrPath = "/etc/stacks/lidarr/config";
  my = config.services.my.lidarr;
in
{
  systemd.tmpfiles.rules = [
    "d ${lidarrPath}/config 0755 root root"
  ];

  services.my.lidarr = {
    port = 8686;
    domain = "lidarr.lab.keyruu.de";
  };

  virtualisation.quadlet.containers = {
    media-lidarr = {
      containerConfig = {
        image = "ghcr.io/hotio/lidarr:release-3.1.0.4875";
        environments = {
          PUID = "0";
          PGID = "0";
          UMASK = "022";
          TZ = "Europe/Berlin";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${lidarrPath}/config:/config"
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
      "127.0.0.1:${toString my.port}:8686"
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
