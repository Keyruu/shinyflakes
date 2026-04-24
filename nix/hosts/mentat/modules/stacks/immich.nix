{ config, ... }:
let
  my = config.services.my.immich;
in
{
  services.my.immich = {
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
            image = "ghcr.io/immich-app/immich-server:v2.7.5";
            publishPorts = [ "127.0.0.1:${toString my.port}:2283" ];
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "/main/immich:/data"
              "/main:/usr/src/app/extra-main"
            ];
            environmentFiles = [ config.sops.secrets.immichEnv.path ];
          };
          dependsOn = [
            "redis"
            "database"
          ];
        };

        machine-learning = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-machine-learning:v2.7.5";
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
