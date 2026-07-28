{ config, ... }:
let
  my = config.services.my.prowlarr;
  inherit (config.virtualisation.quadlet) containers;
in
{
  services.my.prowlarr = {
    zfs = true;
    port = 9696;
    domain = "prowlarr.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "config" ];
      security.enable = false;

      containers = {
        prowlarr = {
          containerConfig = {
            image = "ghcr.io/hotio/prowlarr:release-2.5.2.5491";
            environments = {
              PUID = "0";
              PGID = "0";
              UMASK = "022";
              TZ = "Europe/Berlin";
            };
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "${my.stack.path}/config:/config"
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
    "127.0.0.1:${toString my.port}:9696"
  ];
}
