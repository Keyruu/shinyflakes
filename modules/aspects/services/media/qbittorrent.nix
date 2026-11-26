{ ... }:
{
  den.aspects.services.media.qbittorrent = {
    nixos =
      { config, ... }:
      let
        my = config.services.my.qbittorrent;
      in
      {
        services.my.qbittorrent = {
          zfs = true;
          port = 8023;
          domain = "qbittorrent.lab.keyruu.de";
          proxy.enable = true;
          backup.enable = true;
          stack = {
            enable = true;
            directories = [
              {
                path = "config";
                mode = "0770";
              }
            ];
            security.enable = false;

            containers = {
              qbittorrent = {
                containerConfig = {
                  image = "ghcr.io/hotio/qbittorrent:release-5.3.1";
                  environments = {
                    PUID = "0";
                    PGID = "0";
                    UMASK = "007";
                    TZ = "Europe/Berlin";
                    WEBUI_PORTS = "8080/tcp";
                  };
                  volumes = [
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
          "127.0.0.1:${toString my.port}:8080"
        ];
      };
  };
}
