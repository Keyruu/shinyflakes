{ config, ... }:
let
  my = config.services.my.actualbudget;
in
{
  services.my.actualbudget = {
    port = 5006;
    domain = "budget.lab.keyruu.de";
    proxy.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = false;

      containers = {
        actualbudget = {
          containerConfig = {
            image = "docker.io/actualbudget/actual-server:26.7.0";
            publishPorts = [ "127.0.0.1:${toString my.port}:5006" ];
            volumes = [
              "${my.stack.path}/data:/data"
            ];
          };
        };
      };
    };
  };
}
