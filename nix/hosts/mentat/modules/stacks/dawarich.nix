{ config, flake, ... }:
let
  my = config.services.my.dawarich;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    dawarichDatabasePassword = { };
    dawarichSecretKeyBase = { };
  };

  sops.templates."dawarich.env" = {
    restartUnits =
      with containers;
      map quadlet.service [
        dawarich-app
        dawarich-sidekiq
        dawarich-db
      ];
    content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder.dawarichDatabasePassword}
      DATABASE_PASSWORD=${config.sops.placeholder.dawarichDatabasePassword}
      SECRET_KEY_BASE=${config.sops.placeholder.dawarichSecretKeyBase}
    '';
  };

  services.my.dawarich =
    let
      domain = "map.peeraten.net";
    in
    {
      port = 3001;
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
            path = "db-data";
            mode = "0700";
            owner = "999";
            group = "999";
          }
          "shared"
          "public"
          "watched"
          "storage"
        ];
        network.enable = true;
        security.enable = false;

        containers =
          let
            # renovate: datasource=docker depName=freikin/dawarich
            version = "1.3.4";
          in
          {
            redis = {
              containerConfig = {
                image = "redis:7.4-alpine";
                exec = "redis-server";
                volumes = [
                  "${my.stack.path}/shared:/data"
                ];
                networkAliases = [ "dawarich_redis" ];
                healthCmd = "redis-cli --raw incr ping";
                healthInterval = "10s";
                healthTimeout = "10s";
                healthRetries = 5;
                healthStartPeriod = "30s";
              };
            };

            db = {
              containerConfig = {
                image = "postgis/postgis:17-3.5-alpine";
                shmSize = "1g";
                environments = {
                  POSTGRES_USER = "postgres";
                  POSTGRES_DB = "dawarich_development";
                };
                environmentFiles = [ config.sops.templates."dawarich.env".path ];
                volumes = [
                  "${my.stack.path}/db-data:/var/lib/postgresql/data:Z"
                  "${my.stack.path}/shared:/var/shared"
                ];
                networkAliases = [ "dawarich_db" ];
                healthCmd = "pg_isready -U postgres -d dawarich_development";
                healthInterval = "10s";
                healthTimeout = "10s";
                healthRetries = 5;
                healthStartPeriod = "30s";
              };
            };

            app = {
              containerConfig = {
                image = "freikin/dawarich:${version}";
                exec = "web-entrypoint.sh bin/rails server -p 3000 -b ::";
                publishPorts = [
                  "127.0.0.1:${toString my.port}:3000"
                  "${config.services.mesh.ip}:${toString my.port}:3000"
                ];
                volumes = [
                  "${my.stack.path}/public:/var/app/public"
                  "${my.stack.path}/watched:/var/app/tmp/imports/watched"
                  "${my.stack.path}/storage:/var/app/storage"
                  "${my.stack.path}/db-data:/dawarich_db_data"
                ];
                environments = {
                  RAILS_ENV = "development";
                  REDIS_URL = "redis://dawarich_redis:6379";
                  DATABASE_HOST = "dawarich_db";
                  DATABASE_PORT = "5432";
                  DATABASE_USERNAME = "postgres";
                  DATABASE_NAME = "dawarich_development";
                  MIN_MINUTES_SPENT_IN_CITY = "60";
                  APPLICATION_HOSTS = "localhost,map.peeraten.net";
                  TIME_ZONE = "Europe/Berlin";
                  APPLICATION_PROTOCOL = "https";
                  PROMETHEUS_EXPORTER_ENABLED = "false";
                  PROMETHEUS_EXPORTER_HOST = "0.0.0.0";
                  PROMETHEUS_EXPORTER_PORT = "9394";
                  RAILS_LOG_TO_STDOUT = "true";
                  SELF_HOSTED = "true";
                  STORE_GEODATA = "true";
                };
                environmentFiles = [ config.sops.templates."dawarich.env".path ];
              };
              dependsOn = [
                "db"
                "redis"
              ];
            };

            sidekiq = {
              containerConfig = {
                image = "freikin/dawarich:${version}";
                exec = "sidekiq-entrypoint.sh sidekiq";
                volumes = [
                  "${my.stack.path}/public:/var/app/public"
                  "${my.stack.path}/watched:/var/app/tmp/imports/watched"
                  "${my.stack.path}/storage:/var/app/storage"
                ];
                environments = {
                  RAILS_ENV = "development";
                  REDIS_URL = "redis://dawarich_redis:6379";
                  DATABASE_HOST = "dawarich_db";
                  DATABASE_PORT = "5432";
                  DATABASE_USERNAME = "postgres";
                  DATABASE_NAME = "dawarich_development";
                  APPLICATION_HOSTS = "localhost,map.peeraten.net";
                  BACKGROUND_PROCESSING_CONCURRENCY = "10";
                  APPLICATION_PROTOCOL = "https";
                  PROMETHEUS_EXPORTER_ENABLED = "false";
                  PROMETHEUS_EXPORTER_HOST = "dawarich-app";
                  PROMETHEUS_EXPORTER_PORT = "9394";
                  RAILS_LOG_TO_STDOUT = "true";
                  SELF_HOSTED = "true";
                  STORE_GEODATA = "true";
                };
                environmentFiles = [ config.sops.templates."dawarich.env".path ];
                healthCmd = "pgrep -f sidekiq";
                healthInterval = "10s";
                healthTimeout = "10s";
                healthRetries = 30;
                healthStartPeriod = "30s";
              };
              dependsOn = [
                "db"
                "redis"
                "app"
              ];
            };
          };
      };
    };
}
