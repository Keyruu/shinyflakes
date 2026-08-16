{ ... }:
{
  den.aspects.services.karakeep = {
    nixos = { config, ... }:
      let
        my = config.services.my.karakeep;
      in
      {
        sops.secrets = {
          openaiKey = { };
          karakeepNextauthSecret = { };
          karakeepMeiliMasterKey = { };
          karakeepClientSecret = { };
        };

        sops.templates."karakeep.env" = {
          restartUnits = [
            "karakeep-web.service"
            "karakeep-meilisearch.service"
          ];
          content = # sh
            ''
              NEXTAUTH_SECRET=${config.sops.placeholder.karakeepNextauthSecret}
              MEILI_MASTER_KEY=${config.sops.placeholder.karakeepMeiliMasterKey}
              NEXTAUTH_URL=https://karakeep.lab.keyruu.de
              DISABLE_SIGNUPS=true
              OPENAI_API_KEY=${config.sops.placeholder.openaiKey}
              OAUTH_WELLKNOWN_URL=https://auth.peeraten.net/.well-known/openid-configuration
              OAUTH_CLIENT_ID=karakeep
              OAUTH_CLIENT_SECRET=${config.sops.placeholder.karakeepClientSecret}
              OAUTH_PROVIDER_NAME=Authelia
              # link the existing password account by matching email (authelia emails are trusted)
              OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING=true
              DISABLE_PASSWORD_AUTH=true
            '';
        };

        services.my.karakeep = {
          title = "Karakeep";
          description = "Bookmarks";
          port = 3000;
          domain = "karakeep.lab.keyruu.de";
          dashboard = {
            enable = true;
            groups = [ "karakeep_users" ];
          };
          oidc = {
            enable = true;
            # pbkdf2 hash of sops.karakeepClientSecret
            clientSecret = "$pbkdf2-sha512$310000$OysQ.ABOca710He0J/6sLQ$y5QXX0NxBPtmr11BdlfQiWSd5d96PET7yIXoPCn8oFX8RC85RkQ8/w1AdjUphpRnomWCT2Ea1eSl.n.xOSvFug";
            redirectUris = [ "https://karakeep.lab.keyruu.de/api/auth/callback/custom" ];
            # karakeep reads email from the ID token instead of userinfo (not OIDC-conformant);
            # the named policy `karakeep` is declared inline in authelia.nix.
            claimsPolicy = "karakeep";
          };
          monitor.conditions = [ "[STATUS] == 403" ];
          proxy = {
            enable = true;
            whitelist = {
              enable = true;
              people = [ "lucas" ];
            };
          };
          backup.enable = true;
          stack = {
            enable = true;
            directories = [
              "data"
              "meilisearch"
            ];
            network.enable = true;
            security.enable = false;

            containers = {
              web = {
                containerConfig = {
                  image = "ghcr.io/karakeep-app/karakeep:0.33.1";
                  publishPorts = [ "127.0.0.1:${toString my.port}:3000" ];
                  volumes = [
                    "${my.stack.path}/data:/data"
                  ];
                  environments = {
                    MEILI_ADDR = "http://karakeep-meilisearch:7700";
                    BROWSER_WEB_URL = "http://karakeep-chrome:9222";
                    DATA_DIR = "/data";
                  };
                  environmentFiles = [ config.sops.templates."karakeep.env".path ];
                };
                dependsOn = [
                  "meilisearch"
                  "chrome"
                ];
              };

              chrome = {
                containerConfig = {
                  image = "gcr.io/zenika-hub/alpine-chrome:124";
                  exec = "--no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 --enable-features=ConversionMeasurement,AttributionReportingCrossAppWeb --hide-scrollbars";
                  networkAliases = [ "chrome" ];
                };
              };

              meilisearch = {
                containerConfig = {
                  image = "docker.io/getmeili/meilisearch:v1.13.3";
                  environments = {
                    MEILI_NO_ANALYTICS = "true";
                  };
                  environmentFiles = [ config.sops.templates."karakeep.env".path ];
                  volumes = [
                    "${my.stack.path}/meilisearch:/meili_data"
                  ];
                  networkAliases = [ "meilisearch" ];
                };
              };
            };
          };
        };
      };
  };
}
