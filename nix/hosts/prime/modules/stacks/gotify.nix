{ config, flake, ... }:
let
  my = config.services.my.gotify;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets.gotifyDefaultPassword = { };

  sops.templates."gotify.env" = {
    restartUnits = [ (quadlet.service containers.gotify) ];
    content = ''
      GOTIFY_DEFAULTUSER_PASS=${config.sops.placeholder.gotifyDefaultPassword}
    '';
  };

  services.my.gotify = {
    port = 8080;
    domain = "notify.keyruu.de";
    proxy = {
      enable = true;
      server = "caddy";
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = true;

      containers.gotify = {
        containerConfig = {
          image = "gotify/server:latest";
          publishPorts = [ "127.0.0.1:${toString my.port}:8080" ];
          volumes = [ "${my.stack.path}/data:/app/data" ];
          environmentFiles = [ config.sops.templates."gotify.env".path ];
          environments = {
            GOTIFY_SERVER_PORT = "8080";
          };
        };
      };
    };
  };
}
