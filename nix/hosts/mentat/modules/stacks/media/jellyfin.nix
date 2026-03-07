{ config, ... }:
let
  my = config.services.my.jellyfin;
in
{
  services.my.jellyfin = {
    port = 8096;
    domain = "jellyfin.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        "config"
        "cache"
      ];
      main = "jellyfin";
      internalPort = 8096;
      security.enable = false;

      containers = {
        jellyfin = {
          containerConfig = {
            image = "ghcr.io/jellyfin/jellyfin:10.11.6";
            volumes = [
              "${my.stack.path}/config:/config"
              "${my.stack.path}/cache:/cache"
              "/main/media:/media"
            ];
            publishPorts = [
              "${config.services.mesh.ip}:${toString my.port}:${toString my.port}"
            ];
          };
        };
      };
    };
  };
}
