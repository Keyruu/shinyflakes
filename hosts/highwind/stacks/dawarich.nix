{ config, ... }:
let
  stackPath = "/etc/stacks/dawarich";
in
{
  sops.secrets = {
    dawarichDatabasePassword = { };
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/db-data 0770 999 999"
    "d ${stackPath}/shared 0755 root root"
    "d ${stackPath}/public 0755 root root"
    "d ${stackPath}/watched 0755 root root"
    "d ${stackPath}/storage 0755 root root"
  ];

  sops.templates."dawarich.env" = {
    restartUnits = [
      "dawarich-app.service"
      "dawarich-sidekiq.service"
      "dawarich-db.service"
    ];
    content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder.dawarichDatabasePassword}
      DATABASE_PASSWORD=${config.sops.placeholder.dawarichDatabasePassword}
    '';
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.dawarich.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=dawarich" ];
      };

      containers = {
        dawarich-redis = {
          containerConfig = {
            image = "redis:7.4-alpine";
            exec = "redis-server";
            volumes = [
              "${stackPath}/shared:/data"
            ];
            networks = [ networks.dawarich.ref ];
            networkAliases = [ "dawarich_redis" ];
            labels = [ "wud.watch=false" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        dawarich-db = {
          containerConfig = {
            image = "postgis/postgis:17-3.5-alpine";
            environments = {
              POSTGRES_USER = "postgres";
              POSTGRES_DB = "dawarich_development";
            };
            environmentFiles = [ config.sops.templates."dawarich.env".path ];
            volumes = [
              "${stackPath}/db-data:/var/lib/postgresql/data"
              "${stackPath}/shared:/var/shared"
            ];
            networks = [ networks.dawarich.ref ];
            networkAliases = [ "dawarich_db" ];
            labels = [ "wud.watch=false" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        dawarich-app = {
          containerConfig = {
            image = "freikin/dawarich:latest";
            exec = "web-entrypoint.sh bin/rails server -p 3000 -b ::";
            publishPorts = [
              "127.0.0.1:3001:3000"
              "100.64.0.1:3001:3000"
            ];
            volumes = [
              "${stackPath}/public:/var/app/public"
              "${stackPath}/watched:/var/app/tmp/imports/watched"
              "${stackPath}/storage:/var/app/storage"
              "${stackPath}/db-data:/dawarich_db_data"
            ];
            environments = {
              RAILS_ENV = "development";
              REDIS_URL = "redis://dawarich_redis:6379";
              DATABASE_HOST = "dawarich_db";
              DATABASE_USERNAME = "postgres";
              DATABASE_NAME = "dawarich_development";
              MIN_MINUTES_SPENT_IN_CITY = "60";
              APPLICATION_HOSTS = "localhost,map.peeraten.net";
              TIME_ZONE = "Europe/Berlin";
              APPLICATION_PROTOCOL = "https";
              PROMETHEUS_EXPORTER_ENABLED = "false";
              PROMETHEUS_EXPORTER_HOST = "0.0.0.0";
              PROMETHEUS_EXPORTER_PORT = "9394";
              SELF_HOSTED = "true";
              STORE_GEODATA = "true";
            };
            environmentFiles = [ config.sops.templates."dawarich.env".path ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
            ];
            networks = [ networks.dawarich.ref ];
          };
          serviceConfig = {
            Restart = "on-failure";
          };
          unitConfig = {
            After = [
              "dawarich-db.service"
              "dawarich-redis.service"
            ];
            Requires = [
              "dawarich-db.service"
              "dawarich-redis.service"
            ];
          };
        };

        dawarich-sidekiq = {
          containerConfig = {
            image = "freikin/dawarich:latest";
            exec = "sidekiq-entrypoint.sh sidekiq";
            volumes = [
              "${stackPath}/public:/var/app/public"
              "${stackPath}/watched:/var/app/tmp/imports/watched"
              "${stackPath}/storage:/var/app/storage"
            ];
            environments = {
              RAILS_ENV = "development";
              REDIS_URL = "redis://dawarich_redis:6379";
              DATABASE_HOST = "dawarich_db";
              DATABASE_USERNAME = "postgres";
              DATABASE_NAME = "dawarich_development";
              APPLICATION_HOSTS = "localhost,map.peeraten.net";
              BACKGROUND_PROCESSING_CONCURRENCY = "10";
              APPLICATION_PROTOCOL = "https";
              PROMETHEUS_EXPORTER_ENABLED = "false";
              PROMETHEUS_EXPORTER_HOST = "dawarich-app";
              PROMETHEUS_EXPORTER_PORT = "9394";
              SELF_HOSTED = "true";
              STORE_GEODATA = "true";
            };
            environmentFiles = [ config.sops.templates."dawarich.env".path ];
            labels = [ "wud.watch=false" ];
            networks = [ networks.dawarich.ref ];
          };
          serviceConfig = {
            Restart = "on-failure";
          };
          unitConfig = {
            After = [
              "dawarich-db.service"
              "dawarich-redis.service"
              "dawarich-app.service"
            ];
            Requires = [
              "dawarich-db.service"
              "dawarich-redis.service"
              "dawarich-app.service"
            ];
          };
        };
      };
    };

  security.acme = {
    certs."map.peeraten.net" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.nginx.virtualHosts."map.peeraten.net" = {
    useACMEHost = "map.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:3001";
      proxyWebsockets = true;
    };
  };
}
