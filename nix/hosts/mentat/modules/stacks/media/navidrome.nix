{ config, ... }:
let
  my = config.services.my.navidrome;
in
{
  services.my.navidrome = {
    zfs = true;
    port = 4533;
    domain = "navidrome.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = false;

      containers = {
        navidrome = {
          containerConfig = {
            image = "deluan/navidrome:0.61.2";
            publishPorts = [ "127.0.0.1:${toString my.port}:4533" ];
            environments = {
              ND_LOGLEVEL = "info";
              ND_BASEURL = "https://navidrome.lab.keyruu.de";
            };
            volumes = [
              "${my.stack.path}/data:/data"
              "/main/media/Music/library:/music:ro"
            ];
          };
        };
      };
    };
  };
}
