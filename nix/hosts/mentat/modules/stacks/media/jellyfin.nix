{ config, ... }:
let
  my = config.services.my.jellyfin;
in
{
  services.my.jellyfin = {
    zfs = true;
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
      security.enable = false;

      containers = {
        jellyfin = {
          containerConfig = {
            image = "ghcr.io/jellyfin/jellyfin:10.11.8";
            volumes = [
              "${my.stack.path}/config:/config"
              "${my.stack.path}/cache:/cache"
              "/main/media:/media"
            ];
            publishPorts = [
              "127.0.0.1:${toString my.port}:8096"
              "${config.services.mesh.ip}:${toString my.port}:8096"
            ];
          };
        };
      };
    };
  };
}
