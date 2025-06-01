{ ... }:
{
  virtualisation.quadlet.containers.actualbudget = {
    containerConfig = {
      image = "docker.io/actualbudget/actual-server:latest";
      publishPorts = [ "127.0.0.1:5006:5006" ];
      mounts = [
        "type=bind,source=/etc/stacks/actualbudget/data,destination=/data"
      ];
    };
  };

  services.nginx.virtualHosts."budget.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:5006";
      proxyWebsockets = true;
    };
  };
}
