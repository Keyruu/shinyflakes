{ config, lib, ... }:
let
  domain = "matrix.peeraten.net";
  port = 8008;
in
{
  den.aspects.services.matrix = {
    nixos =
      { config, ... }:
      let
        my = config.services.my.matrix;
      in
      {
        sops.secrets = {
          matrixClientSecret = { };
          macaroonSecretKey = { };
          lkJwtAsToken = { };
          lkJwtHsToken = { };
        };
        sops.templates = {
          "lk-jwt-registration.yaml" = {
            restartUnits = [
              "matrix.service"
              "livekit-jwt.service"
            ];
            owner = "matrix";
            group = "matrix";
            mode = "0440";
            content = # yaml
              ''
                id: "livekit-jwt"
                as_token: "${config.sops.placeholder.lkJwtAsToken}"
                hs_token: "${config.sops.placeholder.lkJwtHsToken}"
                sender_localpart: "_livekit_jwt"
                namespaces:
                  users:
                    - exclusive: false
                      regex: ".*"
                # Reachable from synapse on the matrix stack's bridge network.
                url: "http://livekit-jwt:8080"
                # MSC4512: synapse forwards /_matrix/client/(v*|unstable/*)/rtc/livekit/*
                # to this service.
                io.element.msc4512.proxy_prefix: "rtc/livekit"
                io.element.msc4512.proxy_url: "http://livekit-jwt:8080"
              '';
          };
          "homeserver.yaml" = {
            restartUnits = [ "matrix.service" ];
            mode = "0440";
            owner = "matrix";
            group = "matrix";
            content = ''
              server_name: ${domain}
              public_baseurl: https://${domain}
              pid_file: /data/homeserver.pid
              listeners:
                - port: 8008
                  tls: false
                  type: http
                  x_forwarded: true
                  resources:
                    - names: [client, federation]
                      compress: false

              database:
                name: sqlite3
                args:
                  database: /data/homeserver.db

              media_store_path: /data/media_store
              uploads_path: /data/uploads
              max_upload_size: 20000000
              url_preview_enabled: false
              enable_registration: false
              enable_registration_without_verification: false
              report_stats: false
              trusted_key_servers:
                - server_name: matrix.org
              suppress_key_server_warning: true

              signing_key_path: /data/etc/signing.key

              macaroon_secret_key: ${config.sops.placeholder.macaroonSecretKey}

              oidc_providers:
                - idp_id: authelia
                  idp_name: Authelia
                  issuer: https://auth.peeraten.net
                  client_id: matrix
                  client_secret: ${config.sops.placeholder.matrixClientSecret}
                  scopes:
                    - openid
                    - profile
                    - email
                    - groups
                  # `auto` reads from id_token when `openid` is in scopes — but
                  # authelia's id_token only has sub/aud/iat/...; profile/email/groups
                  # claims live in the userinfo endpoint. Force userinfo so
                  # `user.preferred_username`, `user.name`, etc. are available.
                  user_profile_method: "userinfo_endpoint"
                  user_mapping_provider:
                    config:
                      # sub is authelia's UUID (stable cross-client user id);
                      # localpart is the login username (lucas, nadine, simon).
                      subject_template: "{{ user.sub }}"
                      localpart_template: "{{ user.preferred_username }}"
                      display_name_template: "{{ user.name }}"
                      email_template: "{{ user.email }}"

              turn_shared_secret: ${config.sops.placeholder.turnSecret}
              turn_uri:
                - turn:turn.peeraten.net:3478?transport=udp
                - turn:turn.peeraten.net:3478?transport=tcp
                - turns:turn.peeraten.net:5349?transport=tcp
              turn_user_lifetime: 86400000
              turn_allow_guests: false

              experimental_features:
                # MSC4143 (MatrixRTC) — needs synapse v1.140+ for the /rtc/transports
                # endpoint and v1.157+ for this flag (older releases silently ignore it).
                msc4143_enabled: true

              # MatrixRTC v1.161+: synapse no longer mints LiveKit JWTs itself.
              # lk-jwt-service (see livekit-jwt block in this file) does it via
              # the appservice protocol + MSC4512 C-S proxy.
              matrix_rtc:
                transports:
                  - type: livekit
                    url: wss://livekit.peeraten.net

              app_service_config_files:
                - /data/lk-jwt-registration.yaml

              federation_ip_range_whitelist:
                - 127.0.0.1/8
                - 10.0.0.0/8
                - 172.16.0.0/12
                - 192.168.0.0/16
                - 100.64.0.0/10
                - ::1/128
                - fc00::/7
                - fe80::/10
            '';
          };
        };

        networking.firewall.allowedTCPPorts = [ 8448 ];

        services.my.matrix = {
          inherit port;
          inherit domain;
          title = "Matrix";
          description = "Matrix homeserver (Synapse)";
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
            clientSecret = "$pbkdf2-sha512$310000$t5LcQ34xfdjxgMnp37B.nA$yAtJNPb5Ah9p4cC17HgwOQha6U/xTiyjTckMjasv2mzfTxoy3pKvNFl.1uK6YLftsys4Un37ILAIg/BQDlHu0w";
            redirectUris = [ "https://${domain}/_synapse/client/oidc/callback" ];
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
          };
          stack = {
            enable = true;
            user = {
              enable = true;
              uid = 991;
              gid = 991;
            };
            directories = [
              "data"
              "data/etc"
              "data/media_store"
              "data/uploads"
            ];
            security.enable = true;
            network.enable = true;

            containers = {
              matrix = {
                containerConfig = {
                  image = "docker.io/matrixdotorg/synapse:v1.162.0";
                  user = "991:991";
                  publishPorts = [ "127.0.0.1:${toString port}:8008" ];
                  volumes = [
                    "${my.stack.path}/data:/data"
                    "/etc/stacks/matrix/resolv.conf:/etc/resolv.conf:ro"
                    "${config.sops.templates."homeserver.yaml".path}:/data/homeserver.yaml:ro"
                    "${config.sops.templates."lk-jwt-registration.yaml".path}:/data/lk-jwt-registration.yaml:ro"
                  ];
                  environments = {
                    SYNAPSE_CONFIG_PATH = "/data/homeserver.yaml";
                  };
                  healthCmd = "curl --fail --silent --output /dev/null http://localhost:8008/_matrix/client/versions || exit 1";
                  healthInterval = "30s";
                  healthTimeout = "10s";
                  healthRetries = 3;
                  healthStartPeriod = "30s";
                };
              };

              livekit-jwt = {
                containerConfig = {
                  image = "ghcr.io/element-hq/lk-jwt-service:0.7.0";
                  user = "991:991";
                  volumes = [
                    "${config.sops.secrets.livekitApiKey.path}:/lk-key-secret:ro"
                    "${config.sops.templates."lk-jwt-registration.yaml".path}:/registration.yaml:ro"
                  ];
                  environments = {
                    LK_JWT_BIND = "0.0.0.0:8080";
                    LIVEKIT_URL = "wss://livekit.peeraten.net";
                    LIVEKIT_KEY_FILE = "/lk-key-secret";
                    HS_SERVER_NAME = domain;
                    FULL_ACCESS_HOMESERVERS = domain;
                    RUST_LOG = "info";
                  };
                  healthCmd = "/lk-jwt-service-healthcheck";
                  healthInterval = "30s";
                  healthTimeout = "5s";
                  healthRetries = 3;
                  healthStartPeriod = "10s";
                };
              };
            };
          };
        };

        services.caddy.virtualHosts = {
          "${domain}" = {
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString port} {
                header_up X-Forwarded-For {remote_host}
                header_up X-Forwarded-Proto https
              }
            '';
          };
          "${domain}:8448" = {
            listenAddresses = [ ":8448" ];
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString port} {
                header_up X-Forwarded-For {remote_host}
                header_up X-Forwarded-Proto https
              }
            '';
          };
        };

        environment.etc."stacks/matrix/resolv.conf".text = ''
          nameserver 1.0.0.1
          nameserver 1.1.1.1
        '';

      };
  };
}
