{ ... }:
{
  den.aspects.services.isponsorblocktv = {
    nixos = { config, ... }: {
      services.my.isponsorblocktv = {
        dashboard = { enable = false; };
        monitor = { enable = false; };
        stack = {
          enable = true;
          directories = [ "data" ];
          # ponytail: host networking can't enforce all-caps isolation; tighten when the image drops privs
          security.enable = false;

          containers = {
            isponsorblocktv = {
              containerConfig = {
                image = "ghcr.io/dmunozv04/isponsorblocktv:v2.10.0";
                networks = [ "host" ];
                volumes = [
                  "/etc/stacks/isponsorblocktv/data:/app/data"
                ];
              };
            };
          };
        };
      };
    };
  };
}
