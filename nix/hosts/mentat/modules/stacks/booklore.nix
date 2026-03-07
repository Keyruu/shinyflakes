{ config, flake, ... }:
let
  my = config.services.my.booklore;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops = {
    secrets = {
      bookloreMysqlRootPassword = { };
      bookloreMysqlDatabase = { };
      bookloreMysqlUser = { };
      bookloreMysqlPassword = { };
    };
    templates."booklore.env" = {
      restartUnits = map quadlet.service [
        containers.booklore-main
        containers.booklore-mariadb
      ];
      content = ''
        MYSQL_ROOT_PASSWORD=${config.sops.placeholder.bookloreMysqlRootPassword}
        MYSQL_DATABASE=${config.sops.placeholder.bookloreMysqlDatabase}
        MYSQL_USER=${config.sops.placeholder.bookloreMysqlUser}
        MYSQL_PASSWORD=${config.sops.placeholder.bookloreMysqlPassword}
        DB_USER=${config.sops.placeholder.bookloreMysqlUser}
        DB_PASSWORD=${config.sops.placeholder.bookloreMysqlPassword}
        DATABASE_URL=jdbc:mariadb://${quadlet.alias containers.booklore-mariadb}:3306/${config.sops.placeholder.bookloreMysqlDatabase}
      '';
    };
  };

  services.my.booklore =
    let
      domain = "books.port.peeraten.net";
    in
    {
      port = 6060;
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
        directories = [
          {
            path = "data";
            mode = "0755";
            owner = "1000";
            group = "1000";
          }
          {
            path = "bookdrop";
            mode = "0755";
            owner = "1000";
            group = "1000";
          }
          {
            path = "mariadb/config";
            mode = "0755";
            owner = "root";
            group = "root";
          }
        ];
        network.enable = true;
        main = "main";
        internalPort = 6060;
        security.enable = false;

        containers = {
          mariadb = {
            containerConfig = {
              image = "lscr.io/linuxserver/mariadb:11.4.5";
              environments = {
                PUID = "1000";
                PGID = "1000";
                TZ = "Europe/Berlin";
              };
              environmentFiles = [ config.sops.templates."booklore.env".path ];
              volumes = [
                "${my.stack.path}/mariadb/config:/config"
              ];
              networkAliases = [ "mariadb" ];
              healthCmd = "mariadb-admin ping -h localhost";
              healthInterval = "5s";
              healthTimeout = "5s";
              healthRetries = 10;
              healthStartPeriod = "30s";
            };
          };

          main = {
            containerConfig = {
              image = "ghcr.io/booklore-app/booklore:v2.0.6";
              environments = {
                USER_ID = "1000";
                GROUP_ID = "1000";
                TZ = "Europe/Berlin";
              };
              environmentFiles = [ config.sops.templates."booklore.env".path ];
              volumes = [
                "${my.stack.path}/data:/app/data"
                "/main/media/Books:/books"
                "${my.stack.path}/bookdrop:/bookdrop"
              ];
              networkAliases = [ "booklore" ];
              healthCmd = "wget -q -O - http://localhost:6060/api/v1/healthcheck";
              healthInterval = "60s";
              healthTimeout = "10s";
              healthRetries = 5;
              healthStartPeriod = "60s";
            };
            dependsOn = [ "mariadb" ];
          };
        };
      };
    };

  services.nginx.virtualHosts = {
    ${my.domain} = {
      extraConfig = ''
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
        large_client_header_buffers 8 32k;
      '';
    };
  };
}
