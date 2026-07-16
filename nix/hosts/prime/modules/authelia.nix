{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  instance = config.services.authelia.instances.main;
  seed = config.sops.templates."authelia-users-seed.yml";
  live = "/var/lib/authelia-main/users.yml";

  # users.yml = declarative seed (identity, groups, email) merged with live state
  mergeUsers = pkgs.writeShellApplication {
    name = "authelia-merge-users";
    runtimeInputs = [
      pkgs.yq-go
      pkgs.coreutils
    ];
    text = ''
      if [ -f ${live} ]; then
        # shellcheck disable=SC2016 # $state is yq syntax, not shell
        yq eval-all '
          (select(fileIndex==1).users // {}) as $state
          | select(fileIndex==0)
          | .users |= with_entries(.value.password = ($state[.key].password // .value.password))
        ' ${seed.path} ${live} > ${live}.new
        mv ${live}.new ${live}
      else
        cp ${seed.path} ${live}
      fi
      chmod 600 ${live}
    '';
  };
in
{
  imports = [
    flake.modules.private.authelia
  ];

  sops.secrets = {
    autheliaJwtSecret.owner = instance.user;
    autheliaSessionSecret.owner = instance.user;
    autheliaStorageKey.owner = instance.user;
    autheliaOidcHmacSecret.owner = instance.user;
    autheliaOidcJwksKey.owner = instance.user;
    resendApiKey.owner = instance.user;
  };

  services = {
    authelia.instances.main = {
      enable = true;
      secrets = {
        jwtSecretFile = config.sops.secrets.autheliaJwtSecret.path;
        sessionSecretFile = config.sops.secrets.autheliaSessionSecret.path;
        storageEncryptionKeyFile = config.sops.secrets.autheliaStorageKey.path;
        oidcHmacSecretFile = config.sops.secrets.autheliaOidcHmacSecret.path;
        oidcIssuerPrivateKeyFile = config.sops.secrets.autheliaOidcJwksKey.path;
      };
      environmentVariables = {
        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets.resendApiKey.path;
      };
      settings = {
        server.address = "tcp://127.0.0.1:8010";

        authentication_backend.file = {
          path = live;
          watch = true;
          password.algorithm = "argon2";
        };

        # nothing is forward-auth proxied yet, only OIDC clients
        access_control.default_policy = "deny";

        session.cookies = [
          {
            domain = "peeraten.net";
            authelia_url = "https://auth.peeraten.net";
          }
        ];

        storage.local.path = "/var/lib/authelia-main/db.sqlite3";

        notifier.smtp = {
          address = "submission://smtp.resend.com:587";
          username = "resend";
          sender = "Authelia <auth@lab.keyruu.de>";
        };

        identity_providers.oidc = {
          authorization_policies.traccar_access = {
            default_policy = "deny";
            rules = [
              {
                policy = "one_factor";
                subject = "group:traccar_users";
              }
            ];
          };

          clients = [
            {
              client_id = "traccar";
              client_name = "Traccar";
              # pbkdf2 digest of the sops traccarClientSecret (hash is store-safe):
              # nix run nixpkgs#authelia -- crypto hash generate pbkdf2 --variant sha512 \
              #   --password "$(sops decrypt --extract '["traccarClientSecret"]' nix/secrets.yaml)"
              client_secret = "$pbkdf2-sha512$310000$oTo3lzrqLPo8RnnCcAfkLQ$4774FjY4HMgVY1qDx6OuJyAJq1ZzrPVSUCN8sySQxXV.Sie5tmmj3bTolb6wl5QB74Lk2AZDvxiYmcR2qE3GGg";
              authorization_policy = "traccar_access";
              redirect_uris = [ "https://traccar.peeraten.net/api/session/openid/callback" ];
              scopes = [
                "openid"
                "email"
                "profile"
              ];
            }
          ];
        };
      };
    };

    caddy.virtualHosts."auth.peeraten.net".extraConfig = ''
      import coraza-waf
      import cloudflare-only

      reverse_proxy 127.0.0.1:8010
    '';

    restic.backupsWithDefaults = {
      authelia = {
        paths = [ "/var/lib/authelia-main" ];
      };
    };
  };

  systemd.services.authelia-main.serviceConfig.ExecStartPre = [ (lib.getExe mergeUsers) ];
}
