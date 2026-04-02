{ config, ... }:
let
  my = config.services.my.radarr;
  inherit (config.virtualisation.quadlet) containers;
in
{
  services.my.radarr = {
    port = 7878;
    domain = "radarr.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "config" ];
      security.enable = false;

      containers = {
        radarr = {
          containerConfig = {
            image = "ghcr.io/hotio/radarr:release-6.1.1.10360";
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
    "127.0.0.1:${toString my.port}:7878"
  ];
}
