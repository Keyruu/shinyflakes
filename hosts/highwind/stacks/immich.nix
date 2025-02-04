{config, ...}: {
  systemd.tmpfiles.rules = [
    "d /etc/stacks/immich/pgdata 0770 root root"
    "d /etc/stacks/immich/model-cache 0770 root root"
  ];

  virtualisation.quadlet = let
    UPLOAD_LOCATION = "/main/immich";
    IMMICH_VERSION = "v1.125.7";
    STACK_PATH = "/etc/stacks/immich";
    DB_NAME = "immich";
    DB_USER = "postgres";
    inherit (config.virtualisation.quadlet) networks;
  in {
    networks.immich.networkConfig.driver = "bridge";
    containers = {
      immich-server = {
        containerConfig = {
          image = "ghcr.io/immich-app/immich-server:${IMMICH_VERSION}";
          publishPorts = [
            "127.0.0.1:2283:2283"
          ];
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${UPLOAD_LOCATION}:/usr/src/app/upload"
          ];
          environmentFiles = [ config.sops.secrets.immichEnv.path ];
          labels = [ "diun.enable=true" ];
          networks = [ networks.immich.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
        unitConfig = {
          After = ["immich-redis.service" "immich-database.service"];
          Requires = ["immich-redis.service" "immich-database.service"];
        };
      };

      immich-machine-learning = {
        containerConfig = {
          image = "ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION}";
          volumes = [
            "${STACK_PATH}/model-cache:/cache"
          ];
          environmentFiles = [ config.sops.secrets.immichEnv.path ];
          labels = [ "diun.enable=true" ];
          networks = [ networks.immich.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
        unitConfig = {
          After = "immich-server.service";
          Requires = "immich-server.service";
        };
      };

      immich-redis = {
        containerConfig = {
          image = "docker.io/library/redis:6.2-alpine@sha256:c5a607fb6e1bb15d32bbcf14db22787d19e428d59e31a5da67511b49bb0f1ccc";
          healthCmd = "redis-cli ping || exit 1";
          networks = [ networks.immich.ref ];
          networkAliases = [ "redis" ];
          notify="healthy";
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      immich-database = {
        containerConfig = {
          image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
          environmentFiles = [ config.sops.secrets.immichEnv.path ];
          environments = {
            POSTGRES_INITDB_ARGS = "--data-checksums";
          };
          volumes = [
            "${STACK_PATH}/pgdata:/var/lib/postgresql/data:z"
          ];
          exec = "postgres -c shared_preload_libraries=vectors.so -c 'search_path=\"$user\", public, vectors' -c logging_collector=on -c max_wal_size=2GB -c shared_buffers=512MB -c wal_compression=on";
          healthCmd = ''pg_isready --dbname='${DB_NAME}' --username='${DB_USER}' || exit 1; Chksum="$(psql --dbname='${DB_NAME}' --username='${DB_USER}' --tuples-only --no-align --command='SELECT COALESCE(SUM(checksum_failures), 0) FROM pg_stat_database')"; echo "checksum failure count is $Chksum"; [ "$Chksum" = '0' ] || exit 1'';
          healthInterval = "5m";
          healthStartupInterval = "30s";
          healthStartPeriod = "5m";
          networks = [ networks.immich.ref ];
          networkAliases = [ "postgres" ];
          notify="healthy";
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };
  };

  services.nginx.virtualHosts."immich.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:2283";
      proxyWebsockets = true;
    };
  };
}
