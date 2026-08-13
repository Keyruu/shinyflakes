{ ... }:
{
  den.aspects.services.media.lidarr = {
    nixos = { config, ... }:
      let
        my = config.services.my.lidarr;
      in
      {
        services.my.lidarr = {
          zfs = true;
          port = 8686;
          domain = "lidarr.lab.keyruu.de";
          proxy.enable = true;
          backup.enable = true;
          stack = {
            enable = true;
            directories = [ "config" ];
            security.enable = false;

            containers = {
              lidarr = {
                containerConfig = {
                  image = "ghcr.io/hotio/lidarr:release-3.1.0.4875";
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
                  After = [ "media-gluetun.service" ];
                  Requires = [ "media-gluetun.service" ];
                };
              };
            };
          };
        };

        virtualisation.quadlet.containers.media-gluetun.containerConfig.publishPorts = [
          "127.0.0.1:${toString my.port}:8686"
        ];
      };
  };
}
