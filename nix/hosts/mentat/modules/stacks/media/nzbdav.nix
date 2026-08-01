{ config, ... }:
let
  my = config.services.my.nzbdav;
  inherit (config.virtualisation.quadlet) containers;
in
{
  services.my.nzbdav = {
    zfs = true;
    port = 8023;
    domain = "nzbdav.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "config" ];
      security.enable = false;

      containers.nzbdav = {
        containerConfig = {
          image = "docker.io/nzbdav/nzbdav:0.6.4";
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
          healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1";
          healthInterval = "30s";
          healthTimeout = "5s";
          healthRetries = 3;
          healthStartPeriod = "20s";
        };
        unitConfig = {
          After = [ containers.media-gluetun.ref ];
          Requires = [ containers.media-gluetun.ref ];
        };
      };
    };
  };

  virtualisation.quadlet.containers.media-gluetun.containerConfig.publishPorts = [
    "127.0.0.1:${toString my.port}:3000"
    "192.168.100.7:${toString my.port}:3000"
  ];
}
