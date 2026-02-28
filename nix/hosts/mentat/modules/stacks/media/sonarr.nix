{ config, ... }:
let
  stackPath = "/etc/stacks/sonarr";
  my = config.services.my.sonarr;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
  ];

  services.my.sonarr = {
    port = 8989;
    domain = "sonarr.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit = "media-sonarr";
    };
  };

  virtualisation.quadlet.containers = {
    media-sonarr = {
      containerConfig = {
        image = "ghcr.io/hotio/sonarr:release-4.0.16.2944";
        environments = {
          PUID = "0";
          PGID = "0";
          UMASK = "022";
          TZ = "Europe/Berlin";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${stackPath}/config:/config"
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
      "127.0.0.1:${toString my.port}:8989"
    ];
  };
}
