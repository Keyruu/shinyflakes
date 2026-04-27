{ config, ... }:
let
  my = config.services.my.hister;
in
{
  services.my.hister = {
    port = 4433;
    domain = "hister.lab.keyruu.de";
    proxy = {
      enable = true;
      whitelist.enable = true;
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        {
          path = "data";
          mode = "0750";
          owner = "1000";
          group = "1000";
        }
      ];
      security.enable = true;

      containers = {
        hister = {
          security.readOnlyRootFilesystem = false;
          containerConfig = {
            image = "ghcr.io/asciimoo/hister:v0.13.0";
            publishPorts = [ "127.0.0.1:${toString my.port}:4433" ];
            user = "1000:1000";
            volumes = [
              "${my.stack.path}/data:/hister/data"
            ];
            environments = {
              HISTER__SERVER__BASE_URL = "https://${my.domain}";
              HISTER_DATA_DIR = "/hister/data";
            };
          };
        };
      };
    };
  };
}
