{ ... }:
{
  den.aspects.services.immich = {
    nixos = { config, ... }:
      let
        my = config.services.my.immich;
      in
      {
        # immichEnv: postgres + redis auth from /main secrets. ClientSecret is
        # auto-declared by the authelia aspect under `<clientId>ClientSecret`.
        sops.secrets.immichEnv = { };

        # Partial immich config, deep-merged over immich defaults. UI settings
        # for these keys become read-only.
        sops.templates."immich-config.json" = {
          restartUnits = [ "immich-server.service" ];
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
                  image = "ghcr.io/immich-app/immich-machine-learning:v3.1.0";
                  volumes = [
                    "${my.stack.path}/model-cache:/cache"
                  ];
                  environmentFiles = [ config.sops.secrets.immichEnv.path ];
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

        # Photos live outside the stack path — declare a separate backup.
        services.restic.backupsWithDefaults."immich-photos" = {
          paths = [ "/main/immich" ];
        };
      };
  };
}
