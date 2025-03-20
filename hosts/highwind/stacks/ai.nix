{config, pkgs, ...}: {
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    rocmOverrideGfx = "9.0.0";
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "9.0.0";
      HSA_ENABLE_SDMA = "0";
      HCC_AMDGPU_TARGET = "gfx90c";
    };
  };

  sops.secrets.openwebuiEnv.owner = "root";

  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 8081;
    environment = {
      DEFAULT_LOCALE = "en-US";
      ENABLE_OLLAMA_API = "True";
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      ENABLE_OPENAI_API = "True";
      ENABLE_RAG_WEB_SEARCH = "True";
      RAG_WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "https://searxng.lab.keyruu.de/search?q=<query>";
    };
    environmentFile = config.sops.secrets.openwebuiEnv.path;
  };

  services.nginx.virtualHosts."ai.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8081";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."ollama.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:11434";
      proxyWebsockets = true;
    };
  };
}
