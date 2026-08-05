{ config, flake, ... }:
let
  my = config.services.my.liwan;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  services.my.liwan = {
    port = 9042;
    domain = "a.keyruu.de";
    proxy = {
      enable = true;
      server = "caddy";
      cloudflareOnly = true;
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = true;

      containers.liwan = {
        containerConfig = {
          image = "ghcr.io/explodingcamera/liwan:1.6";
          publishPorts = [ "127.0.0.1:${toString my.port}:9042" ];
          volumes = [ "${my.stack.path}/data:/data" ];
          environments = {
            LIWAN_BASE_URL = "https://${my.domain}";
          };
        };
      };
    };
  };
}
