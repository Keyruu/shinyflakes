{ config, ... }:
let
  my = config.services.my.liwan;
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
      directories = [ { path = "data"; owner = "1000"; group = "1000"; } ];
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
