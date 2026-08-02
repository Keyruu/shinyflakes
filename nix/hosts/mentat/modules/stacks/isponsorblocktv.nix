{ config, ... }:
let
  my = config.services.my.isponsorblocktv;
in
{
  services.my.isponsorblocktv = {
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
              "${my.stack.path}/data:/app/data"
            ];
          };
        };
      };
    };
  };
}
