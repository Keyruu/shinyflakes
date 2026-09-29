{ ... }:
let
  domain = "matrix.peeraten.net";
  port = 8008;
in
{
  den.aspects.services.matrix = {
    nixos = { config, ... }:
    let
      my = config.services.my.matrix;
    in
    {
      # Docker DNS resolver is slow for Matrix federation — bypass with
      # cloudflare/quad9 upstream resolvers (matrix.org recommends).
      environment.etc."stacks/matrix/resolv.conf".text = ''
        nameserver 1.0.0.1
        nameserver 1.1.1.1
      '';

      # Federation listener — Cloudflare can't proxy arbitrary TCP, so
      # matrix.peeraten.net must be DNS-only and 8448 publicly reachable.
      networking.firewall.allowedTCPPorts = [ 8448 ];

      sops.secrets.matrixClientSecret = {
        restartUnits = [ "matrix.service" ];
      };

      services.my.matrix = {
        inherit port;
        inherit domain;
        title = "Matrix";
        description = "Matrix homeserver";
        dashboard = {
          enable = true;
          groups = [ "matrix_users" ];
        };
        monitor.healthPath = "/_matrix/client/versions";
        proxy.enable = false;
        backup.enable = true;
        oidc = {
          enable = true;
          clientId = "matrix";
          # pbkdf2-sha512 digest of sops.matrixClientSecret — authelia
          # verifies the plaintext against this. Generate with:
          #   nix run '.?submodules=1#authelia-oidc-client' -- matrix
          clientSecret = "$pbkdf2-sha512$310000$t5LcQ34xfdjxgMnp37B.nA$yAtJNPb5Ah9p4cC17HgwOQha6U/xTiyjTckMjasv2mzfTxoy3pKvNFl.1uK6YLftsys4Un37ILAIg/BQDlHu0w";
          redirectUris = [ "https://${domain}/_continuwuity/oidc/complete" ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
        };
        stack = {
          enable = true;
          directories = [ "db" ];
          security.enable = true;

          containers.matrix = {
            containerConfig = {
              image = "forgejo.ellis.link/continuwuation/continuwuity:v26.9.0-maxperf";
              publishPorts = [ "127.0.0.1:${toString port}:8008" ];
              volumes = [
                "${my.stack.path}/db:/var/lib/continuwuity"
                "/etc/stacks/matrix/resolv.conf:/etc/resolv.conf:ro"
                "${config.sops.secrets.matrixClientSecret.path}:/run/secrets/matrix-client-secret:ro"
              ];
              environments = {
                CONTINUWUITY_SERVER_NAME = domain;
                CONTINUWUITY_DATABASE_PATH = "/var/lib/continuwuity";
                CONTINUWUITY_ADDRESS = "0.0.0.0";
                # tells clients/other servers to reach federation at :8448
                CONTINUWUITY_WELL_KNOWN = ''{"m.server":"${domain}:8448"}'';
                CONTINUWUITY_MAX_REQUEST_SIZE = "20000000";
                CONTINUWUITY_OAUTH__OIDC__DISCOVERY_URL = "https://auth.peeraten.net";
                CONTINUWUITY_OAUTH__OIDC__CLIENT_ID = "matrix";
                CONTINUWUITY_OAUTH__OIDC__CLIENT_SECRET_FILE = "/run/secrets/matrix-client-secret";
                CONTINUWUITY_OAUTH__OIDC__ADDITIONAL_SCOPES = "openid,profile,email,groups";
                CONTINUWUITY_OAUTH__OIDC__PROVIDER_NAME = "Authelia";
                # user picks localpart at first OIDC login
                CONTINUWUITY_OAUTH__OIDC__PROMPT_FOR_LOCALPART = "true";
                CONTINUWUITY_OAUTH__OIDC__EMAIL_CLAIM = "email";
                # OIDC creates users on first login — disable native signup
                CONTINUWUITY_ALLOW_REGISTRATION = "false";
              };
              healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:8008/_matrix/client/versions || exit 1";
              healthInterval = "30s";
              healthTimeout = "10s";
              healthRetries = 3;
              healthStartPeriod = "30s";
            };
          };
        };
      };

      services.caddy.virtualHosts = {
        # Client API on 443 — coraza-waf matches chatto/liwan pattern.
        "${domain}" = {
          extraConfig = ''
            import coraza-waf
            reverse_proxy http://127.0.0.1:${toString port}
          '';
        };
        # Federation on 8448 — server-to-server traffic, skip WAF.
        # Shares matrix.peeraten.net cert via SNI.
        "${domain}:8448" = {
          listenAddresses = [ ":8448" ];
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString port}
          '';
        };
      };
    };
  };
}
