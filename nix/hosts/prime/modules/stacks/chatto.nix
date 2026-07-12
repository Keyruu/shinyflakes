{
  config,
  flake,
  ...
}:
let
  domain = "chat.peeraten.net";
  livekitDomain = "livekit.peeraten.net";
  my = config.services.my.chatto;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    chattoNatsToken = { };
    chattoCookieSigningSecret = { };
    chattoCookieEncryptionSecret = { };
    chattoCoreSecretKey = { };
    chattoAssetsSigningSecret = { };
    chattoLivekitApiSecret = { };
    chattoVapidPublicKey = { };
    chattoVapidPrivateKey = { };
  };

  sops.templates = {
    "chatto.env" = {
      restartUnits = map quadlet.service [
        containers.chatto-chatto
        containers.chatto-livekit
      ];
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
        CHATTO_LIVEKIT_API_KEY=chatto
        CHATTO_LIVEKIT_API_SECRET=${config.sops.placeholder.chattoLivekitApiSecret}
        CHATTO_PUSH_ENABLED=true
        CHATTO_PUSH_VAPID_PUBLIC_KEY=${config.sops.placeholder.chattoVapidPublicKey}
        CHATTO_PUSH_VAPID_PRIVATE_KEY=${config.sops.placeholder.chattoVapidPrivateKey}
        CHATTO_PUSH_VAPID_SUBJECT=https://keyruu.de
        CHATTO_VIDEO_ENABLED=true
        CHATTO_OWNERS_EMAILS=me@keyruu.de
      '';
    };

    "nats.conf" = {
      restartUnits = [ (quadlet.service containers.chatto-nats) ];
      uid = 1000;
      gid = 1000;
      content = ''
        authorization: {
            token: "${config.sops.placeholder.chattoNatsToken}"
        }
      '';
    };

    "chatto-livekit.yaml" = {
      restartUnits = [ (quadlet.service containers.chatto-livekit) ];
      content = ''
        port: 7880
        rtc:
          port_range_start: 50000
          port_range_end: 50200
          use_external_ip: true
        turn:
          enabled: true
          udp_port: 3478
        keys:
          chatto: ${config.sops.placeholder.chattoLivekitApiSecret}
        webhook:
          urls:
            - https://${domain}/webhooks/livekit
          api_key: chatto
        logging:
          level: info
      '';
    };
  };

  networking.firewall.allowedUDPPorts = [ 3478 ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 50000;
      to = 50200;
    }
  ];

  services.my.chatto = {
    port = 4000;
    inherit domain;
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
            image = "nats:2.14";
            exec = "--jetstream --store_dir=/data --config /nats.conf";
            volumes = [
              "${config.sops.templates."nats.conf".path}:/nats.conf:ro"
              "${my.stack.path}/nats-data:/data"
            ];
            user = "1000:1000";
            networkAliases = [ "nats" ];
          };
        };

        livekit = {
          containerConfig = {
            image = "livekit/livekit-server:v1.13.3";
            exec = "--config /etc/livekit.yaml";
            publishPorts = [
              "3478:3478/udp"
              "50000-50200:50000-50200/udp"
              "127.0.0.1:7880:7880"
            ];
            volumes = [
              "${config.sops.templates."chatto-livekit.yaml".path}:/etc/livekit.yaml:ro"
            ];
            healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:7880/";
            healthInterval = "5s";
            healthTimeout = "3s";
            healthRetries = 3;
            healthStartPeriod = "10s";
            networkAliases = [ "livekit" ];
          };
        };

        chatto = {
          containerConfig = {
            image = "ghcr.io/chattocorp/chatto:0.4.9";
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
          dependsOn = [
            "nats"
            "livekit"
          ];
        };
      };
    };
  };

  services.caddy.virtualHosts = {
    ${livekitDomain} = {
      extraConfig = ''
        import websocket /rtc/v1 http://127.0.0.1:7880

        handle {
          import coraza-waf
          reverse_proxy http://127.0.0.1:7880 
        }
      '';
    };
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
}
