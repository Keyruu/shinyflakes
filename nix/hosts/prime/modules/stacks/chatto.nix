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
      '';
    };

    "nats.env" = {
      restartUnits = [ (quadlet.service containers.chatto-nats) ];
      content = ''
        NATS_TOKEN=${config.sops.placeholder.chattoNatsToken}
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
      enable = true;
      server = "caddy";
      whitelist.enable = true;
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
        "chatto-data"
      ];
      network.enable = true;
      security.enable = true;

      containers = {
        nats = {
          containerConfig = {
            image = "nats:2.14";
            exec = "--jetstream --store_dir=/data --auth=$NATS_TOKEN";
            volumes = [ "${my.stack.path}/nats-data:/data" ];
            environmentFiles = [ config.sops.templates."nats.env".path ];
            networkAliases = [ "nats" ];
            addCapabilities = [
              "CHOWN"
              "DAC_OVERRIDE"
              "FOWNER"
              "SETGID"
              "SETUID"
            ];
          };
          security.readOnlyRootFilesystem = false;
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
            image = "ghcr.io/chattocorp/chatto:0.4.4";
            publishPorts = [ "127.0.0.1:${toString my.port}:4000" ];
            volumes = [
              "${my.stack.path}/chatto-config:/config"
              "${my.stack.path}/chatto-data:/data"
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

  services.caddy.virtualHosts.${livekitDomain} = {
    extraConfig = ''
      import cloudflare-only
      reverse_proxy 127.0.0.1:7880
    '';
  };
}
