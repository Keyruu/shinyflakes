{ config, ... }:
let
  my = config.services.my.tidaloader;
in
{
  sops.secrets = {
    tidaloaderUsername = {
      restartUnits = [ "tidaloader.service" ];
    };
    tidaloaderPassword = {
      restartUnits = [ "tidaloader.service" ];
    };
  };

  sops.templates."tidaloader.env" = {
    restartUnits = [ "tidaloader.service" ];
    content = ''
      AUTH_USERNAME=${config.sops.placeholder.tidaloaderUsername}
      AUTH_PASSWORD=${config.sops.placeholder.tidaloaderPassword}
    '';
  };

  services.my.tidaloader = {
    port = 8001;
    domain = "tidaloader.lab.keyruu.de";
    proxy.enable = true;
  };

  virtualisation.quadlet = {
    containers = {
      tidaloader = {
        containerConfig = {
          image = "ghcr.io/rayz3r0/tidaloader@sha256:18d6798568477818eb1b4b6f66cd5a2b3d472c932fde384f67ea2706c856012b";
          publishPorts = [ "127.0.0.1:8001:8001" ];
          volumes = [
            "/main/media/Music/downloads/completed:/music"
          ];
          environments = {
            MUSIC_DIR = "/music";
            MAX_CONCURRENT_DOWNLOADS = "3";
            QUEUE_AUTO_PROCESS = "true";
          };
          environmentFiles = [ config.sops.templates."tidaloader.env".path ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };
  };
}
