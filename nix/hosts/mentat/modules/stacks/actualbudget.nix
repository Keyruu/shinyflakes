{ config, ... }:
let
  my = config.services.my.actualbudget;
in
{
  services.my.actualbudget = {
    port = 5006;
    domain = "budget.lab.keyruu.de";
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

  services.nginx.virtualHosts."${my.domain}" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString my.port}";
      proxyWebsockets = true;
    };
  };
}
