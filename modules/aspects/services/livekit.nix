{ config, lib, ... }:
{
  den.aspects.services.livekit = {
    nixos = { config, ... }: {
      sops.secrets.livekitApiKey = { };

      sops.templates."livekit.yaml" = {
        restartUnits = [ "livekit.service" ];
        content = ''
          port: 7880
          rtc:
            port_range_start: 50000
            port_range_end: 50200
            use_external_ip: true
          turn:
            enabled: false
          keys:
            livekit: ${config.sops.placeholder.livekitApiKey}
          logging:
            level: info
        '';
      };

      networking.firewall.allowedUDPPortRanges = [
        {
          from = 50000;
          to = 50200;
        }
      ];

      services.my.livekit = {
        title = "LiveKit";
        description = "WebRTC SFU for voice/video calls";
        domain = "livekit.peeraten.net";
        port = 7880;
        proxy.enable = false;
        stack = {
          enable = true;
          user.enable = true;
          network.enable = true;
          security.enable = true;
          containers.livekit = {
            containerConfig = {
              image = "docker.io/livekit/livekit-server:v1.13.7";
              exec = "--config /etc/livekit.yaml";
              publishPorts = [
                "50000-50200:50000-50200/udp"
                "127.0.0.1:7880:7880"
              ];
              volumes = [
                "${config.sops.templates."livekit.yaml".path}:/etc/livekit.yaml:ro"
              ];
              healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:7880/";
              healthInterval = "5s";
              healthTimeout = "3s";
              healthRetries = 3;
              healthStartPeriod = "10s";
              networkAliases = [ "livekit" ];
            };
          };
        };
      };

      services.caddy.virtualHosts."livekit.peeraten.net" = {
        extraConfig = ''
          import websocket /rtc/v1 http://127.0.0.1:7880
          handle {
            reverse_proxy http://127.0.0.1:7880
          }
        '';
      };
    };
  };
}
