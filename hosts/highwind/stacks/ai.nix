{ config, pkgs, ... }:
{
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

  services.nginx.virtualHosts."ollama.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:11434";
      proxyWebsockets = true;
    };
  };
}
