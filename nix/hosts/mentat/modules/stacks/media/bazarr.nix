{ config, ... }:
let
  my = config.services.my.bazarr;
  inherit (config.virtualisation.quadlet) containers;
in
{
  services.my.bazarr = {
    port = 6767;
    domain = "bazarr.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "config" ];
      security.enable = false;

      containers = {
        bazarr = {
          containerConfig = {
            image = "ghcr.io/hotio/bazarr:release-1.5.6";
            environments = {
              PUID = "0";
              PGID = "0";
              UMASK = "022";
              TZ = "Europe/Berlin";
              WEBUI_PORTS = "6767/tcp,6767/udp";
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
    "127.0.0.1:${toString my.port}:6767"
  ];
}
