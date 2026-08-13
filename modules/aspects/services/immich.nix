{ ... }:
{
  den.aspects.services.immich = {
    nixos = { config, ... }: {
      services.my.immich = {
        enable = true;
        description = "Photo library";
        zfs = true;
        port = 2283;
        domain = "immich.lab.keyruu.de";
        topology = "external";

        # Cross-cutting concern overrides — only where defaults don't fit.
        dashboard.title = "Immich";
        monitor.healthPath = "/api/server/ping";
        scrape.enable = true;
        oidc = { enable = true; redirectPath = "/api/oauth/redirect"; };

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
                image = "ghcr.io/immich-app/immich-server:v3.1.0";
                publishPorts = [ "127.0.0.1:${toString config.services.my.immich.port}:2283" ];
                volumes = [
                  "/etc/localtime:/etc/localtime:ro"
                  "/main/immich:/data"
                  "/main:/usr/src/app/extra-main"
                ];
                environments.IMMICH_CONFIG_FILE = "/immich-config.json";
              };
              dependsOn = [
                "redis"
                "database"
              ];
            };
            machine-learning = {
              containerConfig = {
                image = "ghcr.io/immich-app/immich-machine-learning:v3.1.0";
                volumes = [
                  "${config.services.my.immich.stack.path}/model-cache:/cache"
                ];
              };
            };
            redis = {
              containerConfig = {
                image = "docker.io/library/redis:6.2-alpine";
                healthCmd = "redis-cli ping || exit 1";
                networkAliases = [ "redis" ];
                notify = "healthy";
              };
            };
            database = {
              containerConfig = {
                image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0";
                environments = {
                  POSTGRES_INITDB_ARGS = "--data-checksums";
                };
                securityLabelDisable = true;
                volumes = [
                  "${config.services.my.immich.stack.path}/pgdata:/var/lib/postgresql/data:z"
                ];
                networkAliases = [ "postgres" ];
              };
            };
          };
        };
      };

      # Photos live outside the stack path — declare a separate backup.
      services.restic.backupsWithDefaults."immich-photos" = {
        paths = [ "/main/immich" ];
      };
    };
  };
}
