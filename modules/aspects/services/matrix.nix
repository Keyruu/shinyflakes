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

      # Continuuity's figment Env provider doesn't support arrays or nested
      # struct values via env vars — both `additional_scopes` and
      # `well_known` need a TOML config file. Scalars stay in env for
      # visibility.
      environment.etc."stacks/matrix/continuwuity.toml".text = ''
        [global.well_known]
        client = "https://${domain}"
        server = "${domain}:8448"

        [global.matrix_rtc]
        foci = [
          { type = "livekit", livekit_service_url = "https://livekit.peeraten.net" },
        ]

        # TURN creds published via `/_matrix/client/v3/capabilities`.
        # Secret is HMAC-shared with coturn (modules/aspects/services/turn.nix).
        turn_uri = [
          "turn:turn.peeraten.net:3478?transport=udp",
          "turn:turn.peeraten.net:3478?transport=tcp",
          "turns:turn.peeraten.net:5349?transport=tcp",
        ]
        turn_secret = "${config.sops.placeholder.turnSecret}"
        turn_ttl = 86400

        [oauth.oidc]
        additional_scopes = [
          "openid",
          "profile",
          "email",
          "groups",
        ]
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
              image = "forgejo.ellis.link/continuwuation/continuwuity:v26.9.1-maxperf";
              publishPorts = [ "127.0.0.1:${toString port}:8008" ];
              volumes = [
                "${my.stack.path}/db:/var/lib/continuwuity"
                "/etc/stacks/matrix/resolv.conf:/etc/resolv.conf:ro"
                "/etc/stacks/matrix/continuwuity.toml:/etc/continuwuity.toml:ro"
                "${config.sops.secrets.matrixClientSecret.path}:/run/secrets/matrix-client-secret:ro"
              ];
              environments = {
                CONTINUWUITY_CONFIG = "/etc/continuwuity.toml";
                CONTINUWUITY_SERVER_NAME = domain;
                CONTINUWUITY_DATABASE_PATH = "/var/lib/continuwuity";
                CONTINUWUITY_ADDRESS = "0.0.0.0";
                CONTINUWUITY_MAX_REQUEST_SIZE = "20000000";
                CONTINUWUITY_OAUTH__OIDC__DISCOVERY_URL = "https://auth.peeraten.net";
                CONTINUWUITY_OAUTH__OIDC__CLIENT_ID = "matrix";
                CONTINUWUITY_OAUTH__OIDC__CLIENT_SECRET_FILE = "/run/secrets/matrix-client-secret";
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
        # Client API on 443 — no WAF: continuwuity already gates every endpoint
        # behind auth and the JSON payloads trip OWASP rules on CR/LF/args
        # (same false-positive pattern as chatto gRPC).
        "${domain}" = {
          extraConfig = ''
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
