{ config, ... }:
let
  stackPath = "/etc/stacks/calibre-web";
  my = config.services.my.calibre-web;
in
{
  users = {
    groups.calibre.gid = 1003;
    users = {
      calibre = {
        isSystemUser = true;
        uid = 1003;
        group = "calibre";
        extraGroups = [ "syncthing" ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 calibre calibre"
    "d ${stackPath}/books 0775 calibre syncthing"
    "d ${stackPath}/ingest 0775 calibre syncthing"
    "d ${stackPath}/plugins 0755 calibre calibre"
  ];

  services = {
    my.calibre-web = {
      port = 8083;
      domain = "calibre.lab.keyruu.de";
      proxy.enable = false;
      backup = {
        enable = true;
        paths = [ stackPath ];
      };
    };
    syncthing.settings.folders.books.path = "${stackPath}/books";
  };

  virtualisation.quadlet = {
    containers = {
      calibre-web = {
        containerConfig = {
          image = "crocodilestick/calibre-web-automated:V3.1.4";
          publishPorts = [ "127.0.0.1:${toString my.port}:8083" ];
          volumes = [
            "${stackPath}/config:/config"
            "${stackPath}/books:/calibre-library"
            "${stackPath}/ingest:/cwa-book-ingest"
            "${stackPath}/plugins:/plugins"
          ];
          environments = {
            PUID = "1003";
            PGID = "1003";
            TZ = "Europe/Berlin";
          };
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };
  };

  services.nginx.virtualHosts = {
    ${my.domain} = {
      useACMEHost = my.proxy.cert.host;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString my.port}";
        proxyWebsockets = true;
      };
      extraConfig = ''
        proxy_busy_buffers_size 1024k;
        proxy_buffers 4 512k;
        proxy_buffer_size 1024k;
      '';
    };
  };
}
