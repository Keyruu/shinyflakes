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
          image = "ghcr.io/rayz3r0/tidaloader:latest@sha256:3ab9b090bd64efce6c91dd141d863c9b984b4338f75fe31802d32e378a738fcb";
          publishPorts = [ "127.0.0.1:${toString my.port}:8001" ];
          volumes = [
            "/main/media/Music/downloads/tidaloader:/music"
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
