{ config, pkgs, ... }:
let
  openwebuiStackPath = "/etc/stacks/openwebui";
in
{
  environment.systemPackages = with pkgs; [
    (llama-cpp.override { cudaSupport = true; })
    python312
    python312Packages.huggingface-hub
    python312Packages.torch
    python312Packages.gguf
    vllm
  ];

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
            image = "ollama/ollama:0.11.10";
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
            image = "ghcr.io/open-webui/open-webui:0.6.28";
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

  networking.firewall.interfaces.librechat.allowedTCPPorts = [
    11434
  ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    11434
  ];

  services.nginx.virtualHosts."ollama.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:11434";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."ai.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:3004";
      proxyWebsockets = true;
    };
  };
}
