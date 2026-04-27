{ config, flake, ... }:
let
  my = config.services.my.tidaloader;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    tidaloaderUsername = { };
    tidaloaderPassword = { };
  };

  sops.templates."tidaloader.env" = {
    restartUnits = [ (quadlet.service containers.tidaloader) ];
    content = ''
      AUTH_USERNAME=${config.sops.placeholder.tidaloaderUsername}
      AUTH_PASSWORD=${config.sops.placeholder.tidaloaderPassword}
    '';
  };

  services.my.tidaloader = {
    zfs = true;
    port = 8001;
    domain = "tidaloader.lab.keyruu.de";
    proxy.enable = true;
    stack = {
      enable = true;
      security.enable = false;

      containers = {
        tidaloader = {
          containerConfig = {
            image = "ghcr.io/rayz3r0/tidaloader:latest@sha256:9eca34863edc49b9ec0223e9249f82965c8ae85f6a17436a67d959fcbb8bcffd";
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
        };
      };
    };
  };
}
