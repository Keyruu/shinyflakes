{ config, flake, ... }:
let
  my = config.services.my.paperless;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    paperlessSecretKey = { };
    paperlessUsername = { };
    paperlessPassword = { };
    paperlessClientSecret = { };
  };

  sops.templates."paperless.env" = {
    restartUnits = [ (quadlet.service containers.paperless-webserver) ];
    content = # sh
      ''
        PAPERLESS_SECRET_KEY=${config.sops.placeholder.paperlessSecretKey}
        PAPERLESS_ADMIN_USER=${config.sops.placeholder.paperlessUsername}
        PAPERLESS_ADMIN_PASSWORD=${config.sops.placeholder.paperlessPassword}
        PAPERLESS_SOCIALACCOUNT_PROVIDERS=${
          builtins.toJSON {
            openid_connect = {
              SCOPE = [
                "openid"
                "profile"
                "email"
              ];
              OAUTH_PKCE_ENABLED = true;
              APPS = [
                {
                  provider_id = "authelia";
                  name = "Authelia";
                  client_id = "paperless";
                  secret = config.sops.placeholder.paperlessClientSecret;
                  settings.server_url = "https://auth.peeraten.net";
                }
              ];
            };
          }
        }
      '';
  };

  systemd.tmpfiles.rules = [
    "A+ /main/documents/consume - - - - default:user:paperless:rwx,default:mask::rwx"
  ];

  services.my.paperless = {
    zfs = true;
    port = 8000;
    domain = "paperless.lab.keyruu.de";
    proxy = {
      enable = true;
      whitelist.enable = true;
    };
    backup.enable = true;
    stack = {
      enable = true;
      user = {
        enable = true;
        name = "paperless";
        uid = 1006;
        group = "paperless";
        gid = 1006;
      };
      directories = [
        "data"
        {
          path = "redisdata";
          mode = "0750";
          owner = "999";
          group = "999";
        }
      ];
      network.enable = true;
      security.enable = true;

      containers = {
        broker = {
          containerConfig = {
            image = "docker.io/library/redis:8";
            volumes = [
              "${my.stack.path}/redisdata:/data"
            ];
            networkAliases = [ "broker" ];
            addCapabilities = [
              "DAC_OVERRIDE"
              "SETUID"
              "SETGID"
              "SETPCAP"
            ];
          };
          security = {
            noNewPrivileges = false;
            readOnlyRootFilesystem = false;
          };
        };

        webserver = {
          containerConfig = {
            image = "ghcr.io/paperless-ngx/paperless-ngx:2.20.15";
            publishPorts = [ "127.0.0.1:${toString my.port}:8000" ];
            volumes = [
              "${my.stack.path}/data:/usr/src/paperless/data"
              "/main/documents/media:/usr/src/paperless/media"
              "/main/documents/export:/usr/src/paperless/export"
              "/main/documents/consume:/usr/src/paperless/consume"
            ];
            environments = {
              PAPERLESS_REDIS = "redis://${quadlet.alias containers.paperless-broker}:6379";
              PAPERLESS_URL = "https://${my.domain}";
              PAPERLESS_OCR_LANGUAGE = "deu";
              PAPERLESS_TIME_ZONE = "Europe/Berlin";
              PAPERLESS_CONSUMER_POLLING = "10";
              PAPERLESS_FILENAME_FORMAT = "{{ created_year }}/{{ correspondent }}/{{ title }}";
              PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
              PAPERLESS_DISABLE_REGULAR_LOGIN = "true";
              PAPERLESS_REDIRECT_LOGIN_TO_SSO = "true";
              USERMAP_UID = toString my.stack.user.uid;
              USERMAP_GID = toString my.stack.user.gid;
            };
            environmentFiles = [ config.sops.templates."paperless.env".path ];
            networkAliases = [ "webserver" ];
            addCapabilities = [
              "SETUID"
              "SETGID"
              "CHOWN"
              "FOWNER"
            ];
          };
          dependsOn = [ "broker" ];
          security.readOnlyRootFilesystem = false;
        };
      };
    };
  };
}
