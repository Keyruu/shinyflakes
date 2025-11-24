{ config, ... }:
let
  stackPath = "/etc/stacks/n8n";
in
{
  sops.secrets = {
    n8nEncryptionKey = { };
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  sops.templates."n8n.env" = {
    restartUnits = [ "n8n.service" ];
    content = ''
      N8N_ENCRYPTION_KEY=${config.sops.placeholder.n8nEncryptionKey}
    '';
  };

  virtualisation.quadlet.containers.n8n = {
    containerConfig = {
      image = "docker.n8n.io/n8nio/n8n:latest";
      publishPorts = [ "127.0.0.1:5678:5678" ];
      volumes = [
        "${stackPath}/data:/home/node/.n8n"
      ];
      environments = {
        DB_TYPE = "sqlite";
        N8N_HOST = "n8n.lab.keyruu.de";
        N8N_PORT = "5678";
        N8N_PROTOCOL = "https";
        WEBHOOK_URL = "https://n8n.lab.keyruu.de/";
      };
      environmentFiles = [ config.sops.templates."n8n.env".path ];
      labels = [
        "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts."n8n.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:5678";
      proxyWebsockets = true;
    };
  };
}
