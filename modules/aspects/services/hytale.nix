{ ... }:
{
  den.aspects.services.hytale = {
    nixos = { config, ... }: {
      sops.secrets.hytaleServerPassword = { };
      sops.templates."hytale-server.env" = {
        content = ''
          HYTALE_PASSWORD=${config.sops.placeholder.hytaleServerPassword}
        '';
      };

      services.my.hytale = {
        dashboard = { enable = false; };
        monitor = { enable = false; };
        stack = {
          enable = false;
          directories = [
            {
              path = "data";
              mode = "0755";
              owner = "1000";
              group = "1000";
            }
          ];
          # ponytail: experimental game server image, unknown internal write paths; tighten when stable
          security.enable = false;

          containers = {
            hytale = {
              containerConfig = {
                image = "docker.io/deinfreu/hytale-server:experimental-0.1.4";
                publishPorts = [ "5520:5520/udp" ];
                volumes = [
                  "/etc/stacks/hytale/data:/home/container"
                  "/etc/machine-id:/etc/machine-id:ro"
                ];
                environmentFiles = [ config.sops.templates."hytale-server.env".path ];
                environments = {
                  SERVER_IP = "0.0.0.0";
                  SERVER_PORT = "5520";
                  PROD = "FALSE";
                  DEBUG = "FALSE";
                  TZ = "Europe/Amsterdam";
                  CACHE = "TRUE";
                  HYTALE_SERVER_NAME = "Der Server";
                  HYTALE_MOTD = "Was geht ab, ihr Oberloser?";
                  HYTALE_MAX_PLAYERS = "1000";
                  HYTALE_MAX_VIEW_RADIUS = "32";
                  HYTALE_COMPRESSION = "false";
                  HYTALE_WORLD = "petershausen";
                  HYTALE_GAMEMODE = "Adventure";
                  HYTALE_ALLOW_OP = "TRUE";
                };
              };
            };
          };
        };
      };
    };
  };
}
