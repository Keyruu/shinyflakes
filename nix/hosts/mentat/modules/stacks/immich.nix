{ config, pkgs, ... }:
let
  stackPath = "/etc/stacks/immich";
  my = config.services.my.immich;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/pgdata 0770 999 999"
    "d ${stackPath}/model-cache 0770 root root"
  ];

  services.my.immich = {
    port = 2283;
    domain = "immich.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit = "immich-*";
    };
  };

  virtualisation.quadlet =
    let
      UPLOAD_LOCATION = "/main/immich";
      # renovate: datasource=docker depName=ghcr.io/immich-app/immich-server
      IMMICH_VERSION = "v2.5.2";
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.immich.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=immich" ];
      };

      containers = {
        immich-server = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-server:${IMMICH_VERSION}";
            publishPorts = [
              "127.0.0.1:${toString my.port}:2283"
            ];
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "${UPLOAD_LOCATION}:/data"
              "/main:/usr/src/app/extra-main"
            ];
            environmentFiles = [ config.sops.secrets.immichEnv.path ];
            networks = [ networks.immich.ref ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [
              "immich-redis.service"
              "immich-database.service"
            ];
            Requires = [
              "immich-redis.service"
              "immich-database.service"
            ];
          };
        };

        immich-machine-learning = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION}";
            volumes = [
              "${stackPath}/model-cache:/cache"
            ];
            environmentFiles = [ config.sops.secrets.immichEnv.path ];
            labels = [
              "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"
            ];
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
            # renovate: ignore
            image = "docker.io/library/redis:6.2-alpine@sha256:c5a607fb6e1bb15d32bbcf14db22787d19e428d59e31a5da67511b49bb0f1ccc";
            healthCmd = "redis-cli ping || exit 1";
            networks = [ networks.immich.ref ];
            networkAliases = [ "redis" ];
            notify = "healthy";
            labels = [ "wud.watch=false" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        immich-database = {
          containerConfig = {
            # renovate: ignore
            image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0";
            environmentFiles = [ config.sops.secrets.immichEnv.path ];
            environments = {
              POSTGRES_INITDB_ARGS = "--data-checksums";
            };
            securityLabelDisable = true;
            volumes = [
              "${stackPath}/pgdata:/var/lib/postgresql/data:z"
            ];
            networks = [ networks.immich.ref ];
            networkAliases = [ "postgres" ];
            labels = [ "wud.watch=false" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };
      };
    };

  services.restic.backupsWithDefaults = {
    immich-photos = {
      paths = [
        "/main/immich"
      ];
    };
  };
}
