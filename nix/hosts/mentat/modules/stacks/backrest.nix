{ config, flake, ... }:
let
  my = config.services.my.backrest;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.templates."backrest.env" = {
    restartUnits = [
      (quadlet.service containers.backrest)
    ];
    content = ''
      RESTIC_PASSWORD=${config.sops.placeholder.resticPassword}
    '';
  };

  services.my.backrest = {
    port = 9898;
    domain = "backrest.lab.keyruu.de";
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
            image = "ghcr.io/garethgeorge/backrest:v1.12.1";
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
}
