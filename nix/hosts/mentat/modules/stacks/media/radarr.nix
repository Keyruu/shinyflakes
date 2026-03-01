{ config, flake, ... }:
let
  stackPath = "/etc/stacks/radarr";
  my = config.services.my.radarr;
  inherit (config.virtualisation.quadlet) containers;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
  ];

  services.my.radarr = {
    port = 7878;
    domain = "radarr.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit = "media-radarr";
    };
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
        After = [ containers.media-gluetun.ref ];
        Requires = [ containers.media-gluetun.ref ];
      };
    };
    media-gluetun.containerConfig.publishPorts = [
      "127.0.0.1:${toString my.port}:7878"
    ];
  };
}
