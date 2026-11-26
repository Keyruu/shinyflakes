{ ... }:
{
  den.aspects.services.media.dispatcharr = {
    nixos =
      { config, ... }:
      let
        my = config.services.my.dispatcharr;
      in
      {
        services.my.dispatcharr = {
          zfs = true;
          port = 9191;
          domain = "dispatcharr.lab.keyruu.de";
          title = "Dispatcharr";
          proxy.enable = true;
          backup.enable = true;
          stack = {
            enable = true;
            directories = [ "data" ];
            # AIO entrypoint starts internal postgres, redis, nginx and uwsgi as root before su-dropping
            security.enable = false;

            containers = {
              dispatcharr = {
                containerConfig = {
                  image = "ghcr.io/dispatcharr/dispatcharr:0.34.1";
                  # AMD Renoir iGPU for VAAPI stream transcoding
                  devices = [ "/dev/dri:/dev/dri" ];
                  environments = {
                    DISPATCHARR_ENV = "aio";
                    REDIS_HOST = "localhost";
                    CELERY_BROKER_URL = "redis://localhost:6379/0";
                    DISPATCHARR_LOG_LEVEL = "info";
                    TZ = "Europe/Berlin";
                  };
                  volumes = [
                    "/etc/localtime:/etc/localtime:ro"
                    "${my.stack.path}/data:/data"
                    "/main/media:/media"
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
          "127.0.0.1:${toString my.port}:9191"
          "${config.services.mesh.ip}:${toString my.port}:9191"
        ];
      };
  };
}
