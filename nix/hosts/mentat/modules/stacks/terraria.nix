{ config, ... }:
let
  my = config.services.my.terraria;
in
{
  services.my.terraria = {
    stack = {
      enable = true;
      directories = [ "config" ];
      security.enable = false;

      containers = {
        terraria = {
          containerConfig = {
            image = "docker.io/passivelemon/terraria-docker:terraria-1.4.5.5";
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
