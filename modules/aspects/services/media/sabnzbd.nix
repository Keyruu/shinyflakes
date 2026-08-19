{ ... }:
{
  den.aspects.services.media.sabnzbd = {
    nixos = { config, ... }:
      let
        my = config.services.my.sabnzbd;
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
                  image = "lscr.io/linuxserver/sabnzbd:5.0.4";
                  environments = {
                    PUID = "0";
                    PGID = "0";
                    TZ = "Europe/Berlin";
                    WHITELIST = "sabnzbd.lab.keyruu.de,sabnzbd,localhost,127.0.0.1";
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
                  After = [ "media-gluetun.service" ];
                  Requires = [ "media-gluetun.service" ];
                };
              };
            };
          };
        };

        virtualisation.quadlet.containers.media-gluetun.containerConfig.publishPorts = [
          "${toString my.port}:8085"
        ];
      };
  };
}
