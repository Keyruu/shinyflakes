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

        # nothing is forward-auth proxied yet, only OIDC clients;
        # authelia rejects "deny" as default when no rules exist
        access_control.default_policy = "one_factor";

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
          # karakeep reads email from the ID token instead of userinfo (not OIDC-conformant),
          # see https://www.authelia.com/integration/openid-connect/clients/karakeep/
          claims_policies.karakeep.id_token = [ "email" ];

          authorization_policies = lib.mapAttrs (_: group: {
            default_policy = "deny";
            rules = [
              {
                policy = "one_factor";
                subject = "group:${group}";
              }
            ];
          }) {
            traccar_access = "traccar_users";
            immich_access = "immich_users";
            paperless_access = "paperless_users";
            karakeep_access = "karakeep_users";
            chatto_access = "chatto_users";
            jellyfin_access = "jellyfin_users";
          };

          # client_secret values are pbkdf2 digests of the sops <name>ClientSecret (hash is store-safe):
          # nix run nixpkgs#authelia -- crypto hash generate pbkdf2 --variant sha512 \
          #   --password "$(sops decrypt --extract '["<name>ClientSecret"]' nix/secrets.yaml)"
          clients = [
            {
              client_id = "traccar";
              client_name = "Traccar";
              client_secret = "$pbkdf2-sha512$310000$oTo3lzrqLPo8RnnCcAfkLQ$4774FjY4HMgVY1qDx6OuJyAJq1ZzrPVSUCN8sySQxXV.Sie5tmmj3bTolb6wl5QB74Lk2AZDvxiYmcR2qE3GGg";
              authorization_policy = "traccar_access";
              redirect_uris = [ "https://traccar.peeraten.net/api/session/openid/callback" ];
              scopes = [
                "openid"
                "email"
                "profile"
              ];
            }
            {
              client_id = "immich";
              client_name = "Immich";
              client_secret = "$pbkdf2-sha512$310000$QhbRJZS0kKRqmu6vG4ca4w$kX.mERhv3AmgzQcuiwVPmBwKbiWjCqBb/2QrsMRX2jIYBL0dCvalKgG1ybxo1mWB9VFJKyRg31Zs4JSuwDIszw";
              authorization_policy = "immich_access";
              redirect_uris = [
                "https://immich.lab.keyruu.de/auth/login"
                "https://immich.lab.keyruu.de/user-settings"
                "app.immich:///oauth-callback"
              ];
              scopes = [
                "openid"
                "email"
                "profile"
              ];
              # immich sends the secret in the token request body
              token_endpoint_auth_method = "client_secret_post";
            }
            {
              client_id = "paperless";
              client_name = "Paperless";
              client_secret = "$pbkdf2-sha512$310000$8Ae87YeR85fdzSb383vraQ$tn7EEPTtuqLfFkYCz9Ob66PPyaDhq.ePyQlE/tU390Y4YTVtweYrWZ5AZRtMWLoiTaDPoMJF1Yny0fcWPpPxdw";
              authorization_policy = "paperless_access";
              require_pkce = true;
              pkce_challenge_method = "S256";
              redirect_uris = [ "https://paperless.lab.keyruu.de/accounts/oidc/authelia/login/callback/" ];
              scopes = [
                "openid"
                "email"
                "profile"
              ];
            }
            {
              client_id = "karakeep";
              client_name = "Karakeep";
              client_secret = "$pbkdf2-sha512$310000$OysQ.ABOca710He0J/6sLQ$y5QXX0NxBPtmr11BdlfQiWSd5d96PET7yIXoPCn8oFX8RC85RkQ8/w1AdjUphpRnomWCT2Ea1eSl.n.xOSvFug";
              authorization_policy = "karakeep_access";
              claims_policy = "karakeep";
              redirect_uris = [ "https://karakeep.lab.keyruu.de/api/auth/callback/custom" ];
              scopes = [
                "openid"
                "email"
                "profile"
              ];
            }
            {
              client_id = "jellyfin";
              client_name = "Jellyfin";
              client_secret = "$pbkdf2-sha512$310000$dmBzWqEysSSvtFh5FMm7Jg$CSLvNfuYfDedxPvzmineAamCw3hSLLOdKxQ1kV04e6wGXsscmVi65ENj/6gj9bkkrpUWz2feNjsqfMfJhtab7g";
              authorization_policy = "jellyfin_access";
              require_pkce = true;
              pkce_challenge_method = "S256";
              redirect_uris = [ "https://jellyfin.lab.keyruu.de/sso/OID/redirect/authelia" ];
              scopes = [
                "openid"
                "profile"
                "groups"
              ];
            }
            {
              client_id = "chatto";
              client_name = "Chatto";
              client_secret = "$pbkdf2-sha512$310000$FWnJlvN79QNRXsOzOe.DHw$JrgYpTy8Sb80G50aTy8BMppD1FcDSkxk/o2QsLr5RFmLk6QLEq6Tv1pm8WW/D1bLXEOp/AO5QSvtEK3s3b24Ng";
              authorization_policy = "chatto_access";
              redirect_uris = [ "https://chat.peeraten.net/auth/providers/authelia/callback" ];
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
