{
  den,
  lib,
  ...
}:
let
  # Build one authelia client block from an `oidc-config` quirk entry.
  # Only emit optional fields when they carry meaningful non-default
  # values — authelia's own defaults (e.g. `token_endpoint_auth_method`
  # defaults to `client_secret_basic`, `require_pkce` defaults to false)
  # apply when the field is absent.
  buildClient =
    entry:
    let
      pkce = entry.requirePkce;
      authMethod = entry.tokenEndpointAuthMethod;
      claimsPolicy = entry.claimsPolicy;
    in
    {
      client_id = entry.clientId;
      client_name = entry.title;
      client_secret = entry.clientSecret;
      authorization_policy = "${entry.name}_access";
      redirect_uris = entry.redirectUris;
      scopes = entry.scopes;
    }
    // lib.optionalAttrs (authMethod != null) {
      token_endpoint_auth_method = authMethod;
    }
    // lib.optionalAttrs pkce {
      require_pkce = pkce;
      pkce_challenge_method = entry.pkceChallengeMethod;
    }
    // lib.optionalAttrs (claimsPolicy != null) {
      claims_policy = claimsPolicy;
    };
in
{
  # Phase 5 cutover: clients are generated from the `oidc-config` quirk
  # (collected from every host that emits `services.my.<x>.oidc.enable = true`).
  # All 8 OIDC services migrated: chatto, paperless, immich, traccar,
  # karakeep, jellyfin, gotify, seerr.
  #
  # Bespoke authelia fields not covered by the schema (claims_policy
  # declarations, cors.allowed_origins, …) stay as global settings below.
  # Per-service `claims_policy` client references go through the schema
  # (see karakeep for an example); the policy declarations themselves stay
  # inline because authelia-side config is prime-only.
  den.aspects.server.authelia = {
    nixos =
      {
        config,
        lib,
        pkgs,
        oidc-config,
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

        # Build <service>_access policies from den.people.<name>.service-access.
        # Per-person service grants become one_factor rules on the matching group.
        allAccess = lib.concatLists (
          lib.mapAttrsToList (
            person: p:
            map (svc: {
              inherit person;
              service = svc;
            }) p.service-access
          ) den.people
        );
        services_ = lib.unique (map (entry: entry.service) allAccess);
        # Policy names match `<service>_access` so the client references
        # (built by buildClient from `entry.name`) resolve.
        servicesAccess = map (s: "${s}_access") services_;
        buildPolicy = name: {
          default_policy = "deny";
          rules = [
            {
              policy = "one_factor";
              subject = "group:${lib.removeSuffix "_access" name}_users";
            }
          ];
        };
      in
      {
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
                # karakeep reads email from the ID token instead of userinfo (not OIDC-conformant).
                # The client reference (`claims_policy = "karakeep"`) is set via the
                # `oidc-config` quirk entry in karakeep's services.my.oidc.claimsPolicy.
                # The policy declaration itself stays inline because authelia-side
                # config is prime-only.
                # see https://www.authelia.com/integration/openid-connect/clients/karakeep/
                claims_policies.karakeep.id_token = [ "email" ];

                # allow the static dashboard to call /userinfo cross-origin for group filtering
                cors.allowed_origins = [ "https://dash.peeraten.net" ];
                cors.endpoints = [ "userinfo" ];

                authorization_policies = lib.genAttrs servicesAccess buildPolicy;

                # client_secret values are pbkdf2 digests of the sops <name>ClientSecret (hash is store-safe)
                # Generated from `oidc-config` quirk entries (see phase 5 cutover note above).
                # Each `services.my.<x>` with `oidc.enable = true` produces one client.
                clients = map buildClient oidc-config;
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
      };
  };
}
