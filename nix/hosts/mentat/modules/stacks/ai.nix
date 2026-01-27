{ config, ... }:
let
  openwebuiStackPath = "/etc/stacks/openwebui";
  inherit (config.services.my) openwebui;
  inherit (config.services.my) ollama;
in
{
  systemd.tmpfiles.rules = [
    "d ${openwebuiStackPath}/data 0755 root root"
  ];

  services.my = {
    ollama = {
      port = 11434;
      domain = "ollama.lab.keyruu.de";
      proxy.enable = true;
    };
    openwebui = {
      port = 3004;
      domain = "ai.lab.keyruu.de";
      proxy.enable = true;
    };
  };

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
            image = "ollama/ollama:0.15.2";
            devices = [ "nvidia.com/gpu=all" ];
            publishPorts = [ "${toString ollama.port}:11434" ];
            volumes = [ "/root/.ollama:/root/.ollama" ];
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
            publishPorts = [ "127.0.0.1:${toString openwebui.port}:8080" ];
            volumes = [ "${openwebuiStackPath}/data:/app/backend/data" ];
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
      ollama.port
    ];
    "${config.services.mesh.interface}".allowedTCPPorts = [
      ollama.port
    ];
  };
}
