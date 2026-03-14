{ config, flake, ... }:
let
  my = config.services.my.calibre-web;
in
{
  users = {
    groups.books.gid = 1002;
    users = {
      calibre.extraGroups = [ "books" ];
      root.extraGroups = [ "books" ];
    };
  };

  services.my.calibre-web =
    let
      domain = "books.port.peeraten.net";
    in
    {
      port = 8083;
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
        security.enable = false;
        user = {
          enable = true;
          name = "calibre";
          uid = 1003;
          group = "calibre";
          gid = 1003;
        };
        directories = [
          {
            path = "config";
            mode = "0755";
            owner = "calibre";
            group = "calibre";
          }
          {
            path = "ingest";
            mode = "0755";
            owner = "calibre";
            group = "books";
          }
          {
            path = "plugins";
            mode = "0755";
            owner = "calibre";
            group = "calibre";
          }
        ];

        containers = {
          calibre-web = {
            containerConfig = {
              image = "ghcr.io/crocodilestick/calibre-web-automated:v4.0.6";
              publishPorts = [ "127.0.0.1:${toString my.port}:8083" ];
              environments = {
                PUID = toString my.stack.user.uid;
                PGID = toString config.users.groups.books.gid;
                TZ = "Europe/Berlin";
              };
              volumes = [
                "${my.stack.path}/config:/config"
                "/main/media/Books:/calibre-library"
                "${my.stack.path}/ingest:/ingest"
                "${my.stack.path}/plugins:/plugins"
              ];
            };
          };
        };
      };
    };

  services.nginx.virtualHosts.${my.domain} = {
    extraConfig = ''
      proxy_busy_buffers_size 1024k;
      proxy_buffers 4 512k;
      proxy_buffer_size 1024k;
    '';
  };
}
