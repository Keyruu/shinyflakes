{ config, flake, ... }:
let
  stackPath = "/etc/stacks/booklore";
  my = config.services.my.booklore;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadletToService;
in
{
  sops.secrets = {
    bookloreMysqlRootPassword = { };
    bookloreMysqlDatabase = { };
    bookloreMysqlUser = { };
    bookloreMysqlPassword = { };
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/books 0755 root root"
    "d ${stackPath}/bookdrop 0755 root root"
    "d ${stackPath}/mariadb/config 0755 root root"
  ];

  sops.templates."booklore.env" = {
    restartUnits = map quadletToService [
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
      DATABASE_URL=jdbc:mariadb://booklore_mariadb:3306/${config.sops.placeholder.bookloreMysqlDatabase}
    '';
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
      backup = {
        enable = true;
        paths = [ stackPath ];
        systemd.unit = "booklore-*";
      };
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.booklore.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=booklore" ];
      };

      containers = {
        booklore-mariadb = {
          containerConfig = {
            image = "lscr.io/linuxserver/mariadb:11.4.5";
            environments = {
              PUID = "1000";
              PGID = "1000";
              TZ = "Europe/Berlin";
            };
            environmentFiles = [ config.sops.templates."booklore.env".path ];
            volumes = [
              "${stackPath}/mariadb/config:/config"
            ];
            networks = [ networks.booklore.ref ];
            networkAliases = [ "booklore_mariadb" ];
            healthCmd = "mariadb-admin ping -h localhost";
            healthInterval = "5s";
            healthTimeout = "5s";
            healthRetries = 10;
            healthStartPeriod = "30s";
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        booklore-main = {
          containerConfig = {
            image = "ghcr.io/booklore-app/booklore:v2.0.5";
            environments = {
              USER_ID = "1000";
              GROUP_ID = "1000";
              TZ = "Europe/Berlin";
            };
            environmentFiles = [ config.sops.templates."booklore.env".path ];
            publishPorts = [
              "127.0.0.1:${toString my.port}:6060"
            ];
            volumes = [
              "${stackPath}/data:/app/data"
              "${stackPath}/books:/books"
              "${stackPath}/bookdrop:/bookdrop"
            ];
            networks = [ networks.booklore.ref ];
            networkAliases = [ "booklore" ];
            healthCmd = "wget -q -O - http://localhost:6060/api/v1/healthcheck";
            healthInterval = "60s";
            healthTimeout = "10s";
            healthRetries = 5;
            healthStartPeriod = "60s";
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [ containers.booklore-mariadb.ref ];
            Requires = [ containers.booklore-mariadb.ref ];
          };
        };
      };
    };
}
