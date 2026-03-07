{ config, flake, ... }:
let
  my = config.services.my.n8n;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    n8nEncryptionKey = { };
  };

  sops.templates."n8n.env" = {
    restartUnits = [ (quadlet.service containers.n8n) ];
    content = ''
      N8N_ENCRYPTION_KEY=${config.sops.placeholder.n8nEncryptionKey}
    '';
  };

  services.my.n8n = {
    port = 5678;
    domain = "n8n.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = false;

      containers = {
        n8n = {
          containerConfig = {
            image = "docker.n8n.io/n8nio/n8n:latest";
            volumes = [
              "${my.stack.path}/data:/home/node/.n8n"
            ];
            environments = {
              DB_TYPE = "sqlite";
              N8N_HOST = "n8n.lab.keyruu.de";
              N8N_PORT = "5678";
              N8N_PROTOCOL = "https";
              WEBHOOK_URL = "https://n8n.lab.keyruu.de/";
            };
            environmentFiles = [ config.sops.templates."n8n.env".path ];
          };
        };
      };
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
