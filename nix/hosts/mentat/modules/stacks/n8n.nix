{ config, ... }:
let
  stackPath = "/etc/stacks/n8n";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0770 1000 1000"
  ];

  virtualisation.quadlet.containers.n8n = {
    containerConfig = {
      image = "docker.n8n.io/n8nio/n8n:1.120.4";
      publishPorts = [
        "127.0.0.1:5678:5678"
        "100.64.0.1:5678:5678"
      ];
      volumes = [
        "${stackPath}/data:/home/node/.n8n"
      ];
      environments = {
        TZ = "Europe/Berlin";
        N8N_PORT = "5678";
        N8N_PROTOCOL = "https";
        N8N_HOST = "n8n.keyruu.de";
        N8N_PATH = "";
        WEBHOOK_URL = "https://n8n.lab.keyruu.de";
      };
      labels = [
        "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  security.acme.certs = {
    "n8n.keyruu.de" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.nginx.virtualHosts."n8n.keyruu.de" = {
    useACMEHost = "n8n.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:5678";
      proxyWebsockets = true;
    };
  };
}
