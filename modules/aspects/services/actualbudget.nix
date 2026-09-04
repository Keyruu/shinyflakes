{ ... }:
{
  den.aspects.services.actualbudget = {
    nixos = { config, ... }: {
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
                image = "docker.io/actualbudget/actual-server:26.9.0";
                publishPorts = [ "127.0.0.1:5006:5006" ];
                volumes = [
                  "/etc/stacks/actualbudget/data:/data"
                ];
              };
            };
          };
        };
      };
    };
  };
}
