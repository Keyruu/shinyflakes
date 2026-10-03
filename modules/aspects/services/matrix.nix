{ config, lib, ... }:
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
      environment.etc."stacks/matrix/resolv.conf".text = ''
        nameserver 1.0.0.1
        nameserver 1.1.1.1
      '';

      sops.templates."homeserver.yaml" = {
        restartUnits = [ "matrix.service" ];
        content = ''
          server_name: ${domain}
          public_baseurl: https://${domain}
          pid_file: /data/homeserver.pid
          listeners:
            - port: 8008
              tls: false
              type: http
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
          trusted_key_servers:
            - server_name: matrix.org
          suppress_key_server_warning: true

          signing_key_path: /data/etc/signing.key
          old_signing_keys: []

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
              user_mapping_provider:
                config:
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
            msc4140_enabled: true
            msc3866_enabled: true
          livekit:
            livekit_service_url: https://livekit.peeraten.net
            livekit_api_key: livekit
            livekit_api_secret: ${config.sops.placeholder.livekitApiKey}

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

      networking.firewall.allowedTCPPorts = [ 8448 ];

      sops.secrets.matrixClientSecret = { };

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
          # pbkdf2 digest of sops.matrixClientSecret — authelia verifies plaintext against this.
          # Generate with:  nix run '.?submodules=1#authelia-oidc-client' -- matrix
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

          containers.matrix = {
            containerConfig = {
              image = "docker.io/matrixdotorg/synapse:v1.135.2";
              user = "991:991";
              publishPorts = [ "127.0.0.1:${toString port}:8008" ];
              volumes = [
                "${my.stack.path}/data:/data"
                "/etc/stacks/matrix/resolv.conf:/etc/resolv.conf:ro"
                "${config.sops.templates."homeserver.yaml".path}:/data/homeserver.yaml:ro"
              ];
              environments = {
                SYNAPSE_CONFIG_PATH = "/data/homeserver.yaml";
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
        "${domain}" = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString port}
          '';
        };
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
