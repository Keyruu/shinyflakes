{
  config,
  ...
}:
let
  my = config.services.my.koito;
in
{
  services.my.koito = {
    port = 4110;
    domain = "fm.keyruu.de";
    proxy = {
      enable = true;
      server = "caddy";
      cloudflareOnly = true;
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        "data"
      ];
      network.enable = true;

      containers = {
        koito = {
          containerConfig = {
            image = "docker.io/gabehf/koito:v0.3.2";
            publishPorts = [ "127.0.0.1:${toString my.port}:4110" ];
            volumes = [ "${my.stack.path}/data:/etc/koito" ];
            environments = {
              KOITO_SQLITE_ENABLED = true;
              KOITO_CORS_ALLOWED_ORIGINS = "https://keyruu.de,http://localhost:4321";
              KOITO_ENABLE_FULL_IMAGE_CACHE = true;
              KOITO_DEFAULT_THEME = "midnight";
            };
          };
        };
      };
    };
  };
}
