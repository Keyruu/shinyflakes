{ config, pkgs, ... }:
let
  openwebuiStackPath = "/etc/stacks/openwebui";
  my = config.services.my.openwebui;
in
{
  systemd.tmpfiles.rules = [
    "d ${openwebuiStackPath}/data 0755 root root"
  ];

  services.my.openwebui = {
    port = 3004;
    domain = "ai.lab.keyruu.de";
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
            image = "ollama/ollama:0.14.1";
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
            publishPorts = [ "127.0.0.1:${toString my.port}:8080" ];
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

  services.nginx.virtualHosts = {
    "ollama.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:11434";
        proxyWebsockets = true;
      };
    };

    "${my.domain}" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString my.port}";
        proxyWebsockets = true;
      };
    };
  };
}
