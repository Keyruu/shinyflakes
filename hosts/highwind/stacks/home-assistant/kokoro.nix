{ config, ... }:
let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet = {
    networks.kokoro.networkConfig = {
      driver = "bridge";
      podmanArgs = [ "--interface-name=kokoro" ];
    };

    containers = {
      kokoro = {
        containerConfig = {
          image = "ghcr.io/remsky/kokoro-fastapi-gpu:latest";
          publishPorts = [ "127.0.0.1:8880:8880" ];
          devices = [ "nvidia.com/gpu=all" ];
          environments = {
            USE_GPU = "true";
          };
          labels = [
            "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
          ];
          networks = [ networks.kokoro.ref ];
          networkAliases = [ "kokoro" ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      wyoming-openai = {
        containerConfig = {
          image = "ghcr.io/roryeckel/wyoming_openai:latest";
          publishPorts = [ "127.0.0.1:10210:10300" ];
          environments = {
            WYOMING_URI = "tcp://0.0.0.0:10300";
            WYOMING_LOG_LEVEL = "INFO";
            WYOMING_LANGUAGES = "en";
            TTS_OPENAI_URL = "http://kokoro:8880/v1";
            TTS_MODELS = "kokoro";
            TTS_BACKEND = "KOKORO_FASTAPI";
          };
          labels = [
            "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
          ];
          networks = [ networks.kokoro.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
        unitConfig = {
          After = [ "kokoro.service" ];
          Requires = [ "kokoro.service" ];
        };
      };
    };
  };
}
