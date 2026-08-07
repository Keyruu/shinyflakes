{ config, ... }:
let
  my = config.services.my.terraria;
in
{
  services.my.terraria = {
    stack = {
      enable = false;
      directories = [ "config" ];
      security.enable = false;

      containers = {
        terraria = {
          containerConfig = {
            image = "docker.io/passivelemon/terraria-docker:terraria-1.4.5.6";
            publishPorts = [ "7777:7777" ];
            volumes = [
              "${my.stack.path}/config:/opt/terraria/config/"
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
}
