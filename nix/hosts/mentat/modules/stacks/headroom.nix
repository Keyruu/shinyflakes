{ config, flake, ... }:
let
  my = config.services.my.headroom;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  services.my.headroom = {
    port = 8787;
    domain = "headroom.lab.keyruu.de";
    proxy = {
      enable = true;
      whitelist.enable = true;
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = true;

      containers.main = {
        security.readOnlyRootFilesystem = false;
        containerConfig = {
          image = "ghcr.io/chopratejas/headroom:0.27.0";
          publishPorts = [ "127.0.0.1:${toString my.port}:8787" ];
          volumes = [
            "${my.stack.path}/data:/root/.headroom"
          ];
          environments = {
            HEADROOM_MEMORY = "on";
            HEADROOM_OUTPUT_SHAPER = "1";
          };
          exec = [
            "headroom"
            "proxy"
            "--host"
            "0.0.0.0"
            "--port"
            "8787"
            "--memory"
          ];
        };
      };
    };
  };
}
