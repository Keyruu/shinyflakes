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
                publishPorts = [ "127.0.0.1:2283:2283" ];
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
        backup.enable = true;
        proxy.enable = true;
      };

      # Photos live outside the stack path — declare a separate backup.
      services.restic.backupsWithDefaults."immich-photos" = {
        paths = [ "/main/immich" ];
      };
    };

    dashboard = { config, ... }: {
      title = "Immich";
      description = config.services.my.immich.description;
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/immich.svg";
      url = "https://${config.services.my.immich.domain}";
      groups = [ "immich_users" ];
      newTab = true;
    };

    monitor = { config, ... }: {
      url = "https://${config.services.my.immich.domain}/api/server/ping";
      interval = "30s";
      conditions = [ "[STATUS] == 200" ];
    };

    scrape = {
      port = 2283;
      metricsPath = "/metrics";
      interval = "15s";
    };

    public-proxy = { config, ... }: {
      domain = config.services.my.immich.domain;
    };

    oidc-config = { config, ... }: {
      clientId = "immich";
      scopes = [ "openid" "email" "profile" ];
      redirectUri = "https://${config.services.my.immich.domain}/api/oauth/redirect";
      tokenEndpointAuthMethod = "client_secret_post";
    };
  };
}
