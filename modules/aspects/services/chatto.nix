{ ... }:
{
  den.aspects.services.chatto = {
    nixos =
      { config, ... }:
      let
        my = config.services.my.chatto;
        domain = "chat.peeraten.net";
        livekitDomain = "livekit.peeraten.net";
      in
      {
        sops.secrets = {
          chattoNatsToken = { };
          chattoCookieSigningSecret = { };
          chattoCookieEncryptionSecret = { };
          chattoCoreSecretKey = { };
          chattoAssetsSigningSecret = { };
          chattoVapidPublicKey = { };
          chattoVapidPrivateKey = { };
          chattoClientSecret = { };
        };

        sops.templates = {
          "chatto.env" = {
            restartUnits = [ "chatto-chatto.service" ];
            content = ''
              CHATTO_NATS_EMBEDDED_ENABLED=false
              CHATTO_NATS_CLIENT_URL=nats://nats:4222
              CHATTO_NATS_CLIENT_AUTH_METHOD=token
              CHATTO_NATS_CLIENT_TOKEN=${config.sops.placeholder.chattoNatsToken}
              CHATTO_WEBSERVER_URL=https://${domain}
              CHATTO_WEBSERVER_PORT=4000
              CHATTO_WEBSERVER_COOKIE_SIGNING_SECRET=${config.sops.placeholder.chattoCookieSigningSecret}
              CHATTO_WEBSERVER_COOKIE_ENCRYPTION_SECRET=${config.sops.placeholder.chattoCookieEncryptionSecret}
              CHATTO_CORE_SECRET_KEY=${config.sops.placeholder.chattoCoreSecretKey}
              CHATTO_CORE_ASSETS_SIGNING_SECRET=${config.sops.placeholder.chattoAssetsSigningSecret}
              CHATTO_LOG_LEVEL=info
              CHATTO_LOG_FORMAT=json
              CHATTO_OPERATOR_API_ENABLED=true
              CHATTO_OPERATOR_API_SOCKET_PATH=/tmp/chatto/operator.sock
              CHATTO_SMTP_ENABLED=false
              CHATTO_LIVEKIT_ENABLED=true
              CHATTO_LIVEKIT_URL=wss://${livekitDomain}
              CHATTO_LIVEKIT_API_KEY=livekit
              CHATTO_LIVEKIT_API_SECRET=${config.sops.placeholder.livekitApiKey}
              CHATTO_PUSH_ENABLED=true
              CHATTO_PUSH_VAPID_PUBLIC_KEY=${config.sops.placeholder.chattoVapidPublicKey}
              CHATTO_PUSH_VAPID_PRIVATE_KEY=${config.sops.placeholder.chattoVapidPrivateKey}
              CHATTO_PUSH_VAPID_SUBJECT=https://keyruu.de
              CHATTO_VIDEO_ENABLED=true
              CHATTO_OWNERS_EMAILS=lucas@keyruu.de
              CHATTO_AUTH_PROVIDERS_0_ID=authelia
              CHATTO_AUTH_PROVIDERS_0_TYPE=oidc
              CHATTO_AUTH_PROVIDERS_0_LABEL=Authelia
              CHATTO_AUTH_PROVIDERS_0_ISSUER_URL=https://auth.peeraten.net
              CHATTO_AUTH_PROVIDERS_0_CLIENT_ID=chatto
              CHATTO_AUTH_PROVIDERS_0_CLIENT_SECRET=${config.sops.placeholder.chattoClientSecret}
              CHATTO_AUTH_PROVIDERS_0_REQUEST_EMAIL=true
              CHATTO_AUTH_PROVIDERS_0_AUTO_PROVISION=true
            '';
          };

          "nats.conf" = {
            restartUnits = [ "chatto-nats.service" ];
            uid = 1000;
            gid = 1000;
            content = ''
              authorization: {
                  token: "${config.sops.placeholder.chattoNatsToken}"
              }
            '';
          };
        };

        services.my.chatto = {
          title = "Chatto";
          description = "Chat";
          port = 4000;
          inherit domain;
          dashboard = {
            enable = true;
            groups = [ "chatto_users" ];
          };
          oidc = {
            enable = true;
            # pbkdf2 hash of sops.chat toClientSecret — authelia verifies plaintext against this
            clientSecret = "$pbkdf2-sha512$310000$FWnJlvN79QNRXsOzOe.DHw$JrgYpTy8Sb80G50aTy8BMppD1FcDSkxk/o2QsLr5RFmLk6QLEq6Tv1pm8WW/D1bLXEOp/AO5QSvtEK3s3b24Ng";
            redirectUris = [ "https://${domain}/auth/providers/authelia/callback" ];
          };
          proxy = {
            enable = false;
          };
          backup.enable = true;
          stack = {
            enable = true;
            user = {
              enable = true;
              uid = 1000;
              gid = 1000;
            };
            directories = [
              "nats-data"
              "chatto-config"
            ];
            network.enable = true;
            security.enable = true;

            containers = {
              nats = {
                containerConfig = {
                  image = "docker.io/nats:2.15";
                  exec = "--jetstream --store_dir=/data --config /nats.conf";
                  volumes = [
                    "${config.sops.templates."nats.conf".path}:/nats.conf:ro"
                    "${my.stack.path}/nats-data:/data"
                  ];
                  user = "1000:1000";
                  networkAliases = [ "nats" ];
                };
              };

              chatto = {
                containerConfig = {
                  image = "ghcr.io/chattocorp/chatto:0.4.25";
                  publishPorts = [ "127.0.0.1:${toString my.port}:4000" ];
                  user = "1000:1000";
                  volumes = [
                    "${my.stack.path}/chatto-config:/home/chatto/.config"
                  ];
                  environments = {
                    PUID = "1000";
                    PGID = "1000";
                    TZ = "Europe/Berlin";
                  };
                  environmentFiles = [ config.sops.templates."chatto.env".path ];
                  networkAliases = [ "chatto" ];
                };
                dependsOn = [ "nats" ];
              };
            };
          };
        };

        services.caddy.virtualHosts = {
          ${domain} = {
            extraConfig = ''
              import websocket /api/realtime http://127.0.0.1:${toString my.port}

              handle {
                import coraza-waf
                reverse_proxy http://127.0.0.1:${toString my.port} {
                  header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
                }
              }
            '';
          };
        };
      };
  };
}
