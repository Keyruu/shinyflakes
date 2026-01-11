{ config, pkgs, ... }:
let
  openwebuiStackPath = "/etc/stacks/openwebui";
in
{
  systemd.tmpfiles.rules = [
    "d ${openwebuiStackPath}/data 0755 root root"
  ];

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.ai.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=ai" ];
      };

      containers = {
        ollama = {
          containerConfig = {
            image = "ollama/ollama:0.13.5";
            devices = [ "nvidia.com/gpu=all" ];
            publishPorts = [ "11434:11434" ];
            volumes = [ "/root/.ollama:/root/.ollama" ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
            ];
            securityLabelDisable = true;
            networks = [ networks.ai.ref ];
            networkAliases = [ "ollama" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        openwebui = {
          containerConfig = {
            image = "ghcr.io/open-webui/open-webui:0.7.2";
            publishPorts = [ "127.0.0.1:3004:8080" ];
            volumes = [ "${openwebuiStackPath}/data:/app/backend/data" ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
            ];
            networks = [ networks.ai.ref ];
            networkAliases = [ "openwebui" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };
      };
    };

  networking.firewall.interfaces = {
    librechat.allowedTCPPorts = [
      11434
    ];
    "${config.services.mesh.interface}".allowedTCPPorts = [
      11434
    ];
  };

  systemd = {
    services.ollama-keepalive = {
      description = "Keep Ollama qwen3:8b model loaded";
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          pkgs.writeShellScript "preload" # sh
            ''
              ${pkgs.systemd}/bin/systemctl is-active ollama.service && \
              ${pkgs.curl}/bin/curl -s http://127.0.0.1:11434/api/generate -d '{"model": "qwen3:8b", "keep_alive": -1, "options": { "num_ctx": 40000 }}' || true
            '';
      };
    };

    timers.ollama-keepalive = {
      description = "Timer for Ollama model keepalive";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "10min";
        Unit = "ollama-keepalive.service";
      };
    };
  };

  services.nginx.virtualHosts = {
    "ollama.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:11434";
        proxyWebsockets = true;
      };
    };

    "ai.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:3004";
        proxyWebsockets = true;
      };
    };
  };
}
