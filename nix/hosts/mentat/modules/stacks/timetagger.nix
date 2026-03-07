{ config, flake, ... }:
let
  my = config.services.my.timetagger;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    timetaggerCreds = { };
  };

  sops.templates."timetagger.env" = {
    restartUnits = [ (quadlet.service containers.timetagger) ];
    content = ''
      TIMETAGGER_CREDENTIALS=${config.sops.placeholder.timetaggerCreds}
    '';
  };

  services.my.timetagger = {
    port = 8085;
    domain = "timetagger.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = false;

      containers = {
        timetagger = {
          containerConfig = {
            image = "ghcr.io/almarklein/timetagger";
            volumes = [ "${my.stack.path}/data:/root/_timetagger" ];
            environments = {
              TIMETAGGER_BIND = "0.0.0.0:80";
              TIMETAGGER_DATADIR = "/root/_timetagger";
              TIMETAGGER_LOG_LEVEL = "info";
            };
            environmentFiles = [ config.sops.templates."timetagger.env".path ];
          };
          serviceConfig = {
            Restart = "unless-stopped";
          };
        };
      };
    };
  };
}
