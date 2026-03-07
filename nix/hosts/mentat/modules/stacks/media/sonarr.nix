{ config, ... }:
let
  my = config.services.my.sonarr;
  inherit (config.virtualisation.quadlet) containers;
in
{
  services.my.sonarr = {
    port = 8989;
    domain = "sonarr.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "config" ];
      security.enable = false;

      containers = {
        sonarr = {
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
              "${my.stack.path}/config:/config"
              "/main/media:/data"
            ];
            networks = [
              "media-gluetun.container"
            ];
          };
          unitConfig = {
            After = [ containers.media-gluetun.ref ];
            Requires = [ containers.media-gluetun.ref ];
          };
        };
      };
    };
  };

  virtualisation.quadlet.containers.media-gluetun.containerConfig.publishPorts = [
    "127.0.0.1:${toString my.port}:8989"
  ];
}
