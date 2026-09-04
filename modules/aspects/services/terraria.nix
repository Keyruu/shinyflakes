{ ... }:
{
  den.aspects.services.terraria = {
    nixos = { config, ... }: {
      services.my.terraria = {
        dashboard = { enable = false; };
        monitor = { enable = false; };
        stack = {
          enable = false;
          directories = [ "config" ];
          security.enable = false;

          containers = {
            terraria = {
              containerConfig = {
                image = "docker.io/passivelemon/terraria-docker:terraria-1.4.5.8";
                publishPorts = [ "7777:7777" ];
                volumes = [
                  "/etc/stacks/terraria/config:/opt/terraria/config/"
                ];
                environments = {
                  WORLD = "wow";
                  SECURE = "0";
                };
              };
            };
          };
        };
      };
    };
  };
}
