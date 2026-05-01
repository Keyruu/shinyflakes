{ config, ... }:
let
  my = config.services.my.sabnzbd;
  inherit (config.virtualisation.quadlet) containers;
in
{
  services.my.sabnzbd = {
    zfs = true;
    port = 8022;
    domain = "sabnzbd.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "config" ];
      security.enable = false;

      containers = {
        sabnzbd = {
          containerConfig = {
            image = "lscr.io/linuxserver/sabnzbd:5.0.0";
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
    "${toString my.port}:8085"
  ];
}
