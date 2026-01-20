{ config, ... }:
let
  stackPath = "/etc/stacks/calibre-web";
  my = config.services.my.calibre-web;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 1000 1000"
    "d ${stackPath}/books 0755 1000 1000"
  ];

  services.my.calibre-web = {
    port = 8083;
    domain = "calibre.lab.keyruu.de";
    proxy.enable = false;
    backup = {
      enable = true;
      paths = [ stackPath ];
    };
  };

  virtualisation.quadlet = {
    containers = {
      calibre-web = {
        containerConfig = {
          image = "docker.io/linuxserver/calibre-web:0.6.25";
          publishPorts = [ "127.0.0.1:${toString my.port}:8083" ];
          volumes = [
            "${stackPath}/config:/config"
            "${stackPath}/books:/books"
          ];
          environments = {
            PUID = "1000";
            PGID = "1000";
            TZ = "Europe/Berlin";
            DOCKER_MODS = "linuxserver/mods:universal-calibre";
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
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Scheme https;
        client_max_body_size 1024M;

        proxy_busy_buffers_size   1024k;
        proxy_buffers   4 512k;
        proxy_buffer_size   1024k;
      '';
    };
  };
}
