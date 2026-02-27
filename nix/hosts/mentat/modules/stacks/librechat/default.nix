{ config, pkgs, ... }:
let
  stackName = "librechat";
  stackPath = "/etc/stacks/${stackName}";
  my = config.services.my.librechat;
in
{
  imports = [
    ./env.nix
  ];

  systemd.tmpfiles.rules = [
    "d ${stackPath}/api/images 0770 1000 1000"
    "d ${stackPath}/api/uploads 0770 1000 1000"
    "d ${stackPath}/api/logs 0770 1000 1000"
    "d ${stackPath}/mongodb/data 0770 root root"
    "d ${stackPath}/meilisearch/meili_data_v1.12 0770 root root"
    "d ${stackPath}/vectordb/pgdata2 0770 999 999"
    "d /main/data/syncthing/obsidian/ai-conversations/librechat 0770 1000 1000"
  ];

  environment.etc."stacks/${stackName}/api/librechat.yaml".source = ./librechat.yaml;

  services.my.librechat = {
    port = 3080;
    domain = "chat.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit = "librechat-*";
    };
  };

  virtualisation.quadlet =
    let
      RAG_PORT = "8000";
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.librechat = {
        networkConfig = {
          driver = "bridge";
          podmanArgs = [ "--interface-name=librechat" ];
        };
      };

      containers = {
        "${stackName}-api" = {
          containerConfig = {
            image = "ghcr.io/danny-avila/librechat-api:v0.8.2-rc2";
            publishPorts = [ "127.0.0.1:${toString my.port}:3080" ];
            addHosts = [ "host.containers.internal:host-gateway" ];
            volumes = [
              "${stackPath}/api/librechat.yaml:/app/librechat.yaml"
              "${stackPath}/api/images:/app/client/public/images"
              "${stackPath}/api/uploads:/app/uploads"
              "${stackPath}/api/logs:/app/api/logs"
              "/main/data/syncthing/obsidian:/obsidian"
            ];
            addCapabilities = [
              "CAP_NET_RAW"
              "NET_ADMIN"
            ];
            networks = [ networks.librechat.ref ];
            environmentFiles = [ config.sops.templates."librechat.env".path ];
            labels = [
              "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"
            ];
            autoUpdate = "registry";
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [
              "${stackName}-mongodb.service"
              "${stackName}-rag-api.service"
            ];
            Requires = [
              "${stackName}-mongodb.service"
              "${stackName}-rag-api.service"
            ];
            # This will cause the service to restart when the config file changes
            X-RestartTrigger = [
              "${config.environment.etc."stacks/${stackName}/api/librechat.yaml".source}"
            ];
          };
        };

        "${stackName}-mongodb" = {
          containerConfig = {
            image = "mongo";
            exec = "mongod --noauth";
            volumes = [
              "${stackPath}/mongodb/data:/data/db"
            ];
            networks = [ networks.librechat.ref ];
            networkAliases = [ "mongodb" ];
            labels = [ "wud.watch=false" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        "${stackName}-meilisearch" = {
          containerConfig = {
            image = "getmeili/meilisearch:v1.12.3";
            volumes = [
              "${stackPath}/meilisearch/meili_data_v1.12:/meili_data"
            ];
            environments = {
              MEILI_HOST = "http://meilisearch:7700";
              MEILI_NO_ANALYTICS = "true";
            };
            networks = [ networks.librechat.ref ];
            environmentFiles = [ config.sops.templates."librechat.env".path ];
            networkAliases = [ "meilisearch" ];
            labels = [ "wud.watch=false" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        "${stackName}-vectordb" = {
          containerConfig = {
            image = "ankane/pgvector:latest";
            volumes = [
              "${stackPath}/vectordb/pgdata2:/var/lib/postgresql/data"
            ];
            environments = {
              POSTGRES_DB = "mydatabase";
              POSTGRES_USER = "myuser";
            };
            environmentFiles = [ config.sops.templates."librechat.env".path ];
            networks = [ networks.librechat.ref ];
            networkAliases = [ "vectordb" ];
            labels = [ "wud.watch=false" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        "${stackName}-rag-api" = {
          containerConfig = {
            image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest@sha256:4e5085d47187ec6e4215035988ce3b9cc243a1298ab03efbf33ab4cf9ebf7461";
            environments = {
              DB_HOST = "${stackName}-vectordb";
              inherit RAG_PORT;
            };
            networks = [ networks.librechat.ref ];
            environmentFiles = [ config.sops.templates."librechat.env".path ];
            networkAliases = [ "rag_api" ];
            labels = [ "wud.watch=false" ];
            autoUpdate = "registry";
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [ "${stackName}-vectordb.service" ];
            Requires = [ "${stackName}-vectordb.service" ];
          };
        };
      };
    };
}
