{ ... }:
{
  den.aspects.services.backrest = {
    nixos = { config, ... }:
      let
        my = config.services.my.backrest;
      in
      {
        sops.templates."backrest.env" = {
          restartUnits = [
            "backrest.service"
          ];
          content = ''
            RESTIC_PASSWORD=${config.sops.placeholder.resticPassword}
          '';
        };

        services.my.backrest = {
          zfs = true;
          port = 9898;
          domain = "backrest.lab.keyruu.de";
          title = "Backrest";
          dashboard = {
            enable = true;
          };
          monitor.enable = false;
          proxy.enable = true;
          stack = {
            enable = true;
            directories = [
              "data"
              "config"
              "cache"
              "tmp"
            ];
            security.enable = false;

            containers = {
              backrest = {
                containerConfig = {
                  image = "ghcr.io/garethgeorge/backrest:v1.14.1";
                  environmentFiles = [ config.sops.templates."backrest.env".path ];
                  environments = {
                    BACKREST_DATA = "/data";
                    BACKREST_CONFIG = "/config/config.json";
                    XDG_CACHE_HOME = "/cache";
                    TMPDIR = "/tmp";
                    TZ = "Europe/Amsterdam";
                  };
                  volumes = [
                    "${my.stack.path}/data:/data"
                    "${my.stack.path}/config:/config"
                    "${my.stack.path}/cache:/cache"
                    "${my.stack.path}/tmp:/tmp"
                    "/main/backup/restic:/main/backup/restic"
                  ];
                };
              };
            };
          };
        };
      };
  };
}
