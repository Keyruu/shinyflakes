{ config, ... }:
let
  stackPath = "/etc/stacks/perplexica";
in
{
  # SOPS secrets for API keys
  sops.secrets = {
    anthropicKey.owner = "root";
    geminiKey.owner = "root";
    openaiKey.owner = "root";
    scalewayKey.owner = "root";
  };

  # Directory creation
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/uploads 0755 root root"
  ];

  # SOPS template for configuration file
  sops.templates."perplexica-config.toml" = {
    restartUnits = [ "perplexica-app.service" ];
    content = # toml
      ''
        [GENERAL]
        SIMILARITY_MEASURE = "cosine" # "cosine" or "dot"
        KEEP_ALIVE = "5m" # How long to keep Ollama models loaded into memory

        [MODELS.OPENAI]
        API_KEY = "${config.sops.placeholder.openaiKey}"

        [MODELS.ANTHROPIC]
        API_KEY = "${config.sops.placeholder.anthropicKey}"

        [MODELS.GEMINI]
        API_KEY = "${config.sops.placeholder.geminiKey}"

        [MODELS.CUSTOM_OPENAI]
        API_KEY = "${config.sops.placeholder.scalewayKey}"
        API_URL = "https://api.scaleway.ai/28f14df5-01a1-40d6-b09f-046cadfaf4c9/v1"
        MODEL_NAME = "qwen3-235b-a22b-instruct-2507"

        [MODELS.OLLAMA]
        API_URL = "http://ollama:11434" # Ollama API URL - accessible via AI network

        [API_ENDPOINTS]
        SEARXNG = "http://host.containers.internal:8080" # SearxNG API URL - accessible via Gluetun network
      '';
  };

  # Quadlet configuration
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        perplexica-app = {
          containerConfig = {
            image = "itzcrazykns1337/perplexica:main";
            publishPorts = [ "127.0.0.1:3004:3000" ];
            volumes = [
              "${stackPath}/data:/home/perplexica/data"
              "${stackPath}/uploads:/home/perplexica/uploads"
              "${config.sops.templates."perplexica-config.toml".path}:/home/perplexica/config.toml"
            ];
            environments = {
              DATA_DIR = "/home/perplexica";
            };
            labels = [
              "wud.watch=false" # Main tag seems to be a rolling release
            ];
            # Connect to AI network to access Ollama
            networks = [
              networks.ai.ref
            ];
            # Use host network mode to access SearXNG on localhost:4899
            addHosts = [
              "host.containers.internal:host-gateway"
            ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [
              "ollama.service"
              "searxng-server.service"
            ];
            Requires = [
              "ollama.service"
              "searxng-server.service"
            ];
          };
        };
      };
    };

  # Nginx reverse proxy for lab.keyruu.de access
  services.nginx.virtualHosts."perplexica.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
      proxyWebsockets = true;
    };
  };
}
