{ ... }:
{
  den.aspects.services.immich = {
    nixos = { config, ... }:
      let
        my = config.services.my.immich;
      in
      {
        # immichEnv: postgres + redis auth from /main secrets. immichClientSecret
        # is consumed by the OIDC config (pbkdf2 hash for authelia) and the
        # immich-config.json sops template below.
        sops.secrets = {
          immichEnv = { };
          immichClientSecret = { };
        };

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
          title = "Immich";
          description = "Photo library";
          zfs = true;
          port = 2283;
          domain = "immich.lab.keyruu.de";
          topology = "external";

          # Cross-cutting concern overrides — only where defaults don't fit.
          monitor.healthPath = "/api/server/ping";
          scrape.enable = true;
          oidc = {
            enable = true;
            # pbkdf2 hash of sops.immichClientSecret
            clientSecret = "$pbkdf2-sha512$310000$QhbRJZS0kKRqmu6vG4ca4w$kX.mERhv3AmgzQcuiwVPmBwKbiWjCqBb/2QrsMRX2jIYBL0dCvalKgG1ybxo1mWB9VFJKyRg31Zs4JSuwDIszw";
            # Three URIs from the prior inline authelia client (mobile app uses
            # app.immich:/// scheme; web flow uses two distinct paths).
            redirectUris = [
              "https://immich.lab.keyruu.de/auth/login"
              "https://immich.lab.keyruu.de/user-settings"
              "app.immich:///oauth-callback"
            ];
            # immich sends the secret in the token request body
            tokenEndpointAuthMethod = "client_secret_post";
          };

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
