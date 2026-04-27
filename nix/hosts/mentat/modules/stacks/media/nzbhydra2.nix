{ config, ... }:
let
  my = config.services.my.nzbhydra2;
  inherit (config.virtualisation.quadlet) containers;
in
{
  services.my.nzbhydra2 = {
    port = 5076;
    domain = "nzbhydra2.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "config" ];
      security.enable = false;

      containers = {
        nzbhydra2 = {
          containerConfig = {
            image = "lscr.io/linuxserver/nzbhydra2:8.8.0";
            environments = {
              PUID = "0";
              PGID = "0";
              TZ = "Europe/Berlin";
            };
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "${my.stack.path}/config:/config"
              "/main/media/downloads:/data/downloads"
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
    "127.0.0.1:${toString my.port}:5076"
  ];
}
