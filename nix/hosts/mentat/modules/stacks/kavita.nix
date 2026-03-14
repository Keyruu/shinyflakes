{ config, ... }:
let
  my = config.services.my.kavita;
in
{
  services.my.kavita =
    let
      domain = "books.port.peeraten.net";
    in
    {
      port = 5000;
      inherit domain;
      proxy = {
        enable = true;
        cert = {
          provided = false;
          host = domain;
        };
      };
      backup.enable = true;
      stack = {
        enable = true;
        security.enable = true;
        directories = [ "config" ];

        containers = {
          main = {
            containerConfig = {
              image = "ghcr.io/kareadita/kavita:0.8.9";
              publishPorts = [ "127.0.0.1:${toString my.port}:5000" ];
              environments.TZ = "Europe/Berlin";
              volumes = [
                "${my.stack.path}/config:/kavita/config"
                "/main/media/Books:/books"
              ];
            };
          };
        };
      };
    };
}
