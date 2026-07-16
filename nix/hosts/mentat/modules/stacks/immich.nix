{ config, flake, ... }:
let
  my = config.services.my.immich;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    immichEnv = { };
    immichClientSecret = { };
  };

  # partial config, deep-merged over immich defaults; UI settings for these keys become read-only
  sops.templates."immich-config.json" = {
    restartUnits = [ (quadlet.service containers.immich-server) ];
    content = builtins.toJSON {
      oauth = {
        enabled = true;
        issuerUrl = "https://auth.peeraten.net";
        clientId = "immich";
        clientSecret = config.sops.placeholder.immichClientSecret;
        buttonText = "Login with Authelia";
        autoLaunch = true;
      };
      passwordLogin.enabled = false;
    };
  };

  services.my.immich = {
    zfs = true;
    port = 2283;
    domain = "immich.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        {
          path = "pgdata";
          mode = "0770";
          owner = "999";
          group = "999";
        }
        {
          path = "model-cache";
          mode = "0770";
          owner = "root";
          group = "root";
        }
      ];
      network.enable = true;
      security.enable = false;

      containers = {
        server = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-server:v3.0.2";
            publishPorts = [ "127.0.0.1:${toString my.port}:2283" ];
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "/main/immich:/data"
              "/main:/usr/src/app/extra-main"
              "${config.sops.templates."immich-config.json".path}:/immich-config.json:ro"
            ];
            environments.IMMICH_CONFIG_FILE = "/immich-config.json";
            environmentFiles = [ config.sops.secrets.immichEnv.path ];
          };
          dependsOn = [
            "redis"
            "database"
          ];
        };

        machine-learning = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-machine-learning:v3.0.2";
            volumes = [
              "${my.stack.path}/model-cache:/cache"
            ];
            environmentFiles = [ config.sops.secrets.immichEnv.path ];
          };
        };

        redis = {
          containerConfig = {
            image = "docker.io/library/redis:6.2-alpine@sha256:c5a607fb6e1bb15d32bbcf14db22787d19e428d59e31a5da67511b49bb0f1ccc";
            healthCmd = "redis-cli ping || exit 1";
            networkAliases = [ "redis" ];
            notify = "healthy";
          };
        };

        database = {
          containerConfig = {
            image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0";
            environmentFiles = [ config.sops.secrets.immichEnv.path ];
            environments = {
              POSTGRES_INITDB_ARGS = "--data-checksums";
            };
            securityLabelDisable = true;
            volumes = [
              "${my.stack.path}/pgdata:/var/lib/postgresql/data:z"
            ];
            networkAliases = [ "postgres" ];
          };
        };
      };
    };
  };

  services.restic.backupsWithDefaults = {
    immich-photos = {
      paths = [
        "/main/immich"
      ];
    };
  };
}
