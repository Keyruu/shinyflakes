{ config, ... }:
let
  my = config.services.my.actualbudget;
in
{
  services.my.actualbudget = {
    port = 5006;
    domain = "budget.lab.keyruu.de";
    proxy.enable = true;
  };

  virtualisation.quadlet.containers.actualbudget = {
    containerConfig = {
      image = "docker.io/actualbudget/actual-server:latest";
      publishPorts = [ "127.0.0.1:${toString my.port}:5006" ];
      mounts = [
        "type=bind,source=/etc/stacks/actualbudget/data,destination=/data"
      ];
    };
  };
}
