{ ... }:
{
  den.aspects.services.home-assistant.matter = {
    nixos = { config, ... }:
      let
        my = config.services.my.matter;
      in
      {
        services.my.matter = {
        dashboard = { enable = false; };
        monitor = { enable = false; };
          backup.enable = true;
          stack = {
            enable = true;
            directories = [ "data" ];
            security.enable = false;
            containers.matter = {
              containerConfig = {
                image = "ghcr.io/matter-js/python-matter-server:8.1.2";
                environments = {
                  TZ = "Europe/Berlin";
                };
                volumes = [
                  "${my.stack.path}/data:/data"
                ];
                networks = [
                  "host"
                ];
              };
            };
          };
        };
      };
  };
}
