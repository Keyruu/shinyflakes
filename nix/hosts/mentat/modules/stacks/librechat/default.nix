{ config, flake, ... }:
let
  my = config.services.my.librechat;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  imports = [
    ./env.nix
  ];

  systemd.tmpfiles.rules = [
    "d /main/data/syncthing/obsidian/ai-conversations/librechat 0770 1000 1000"
  ];

  environment.etc."stacks/librechat/api/librechat.yaml".source = ./librechat.yaml;

  services.my.librechat = {
    port = 3080;
    domain = "chat.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        {
          path = "api/images";
          mode = "0770";
          owner = "1000";
          group = "1000";
        }
        {
          path = "api/uploads";
          mode = "0770";
          owner = "1000";
          group = "1000";
        }
        {
          path = "api/logs";
          mode = "0770";
          owner = "1000";
          group = "1000";
        }
        "mongodb/data"
        "meilisearch/meili_data_v1.35"
        {
          path = "vectordb/pgdata2";
          mode = "0770";
          owner = "999";
          group = "999";
        }
      ];
      network.enable = true;
      security.enable = false;

      containers = {
        api = {
          containerConfig = {
            image = "ghcr.io/danny-avila/librechat-api:v0.8.3-rc2";
            publishPorts = [ "127.0.0.1:${toString my.port}:3080" ];
            addHosts = [ "host.containers.internal:host-gateway" ];
            volumes = [
              "${my.stack.path}/api/librechat.yaml:/app/librechat.yaml"
              "${my.stack.path}/api/images:/app/client/public/images"
              "${my.stack.path}/api/uploads:/app/uploads"
              "${my.stack.path}/api/logs:/app/api/logs"
              "/main/data/syncthing/obsidian:/obsidian"
            ];
            environmentFiles = [ config.sops.templates."librechat.env".path ];
            autoUpdate = "registry";
          };
          dependsOn = [
            "mongodb"
            "rag-api"
          ];
          unitConfig = {
            X-RestartTrigger = [
              config.environment.etc."stacks/librechat/api/librechat.yaml".source
            ];
          };
        };

        mongodb = {
          containerConfig = {
            image = "mongo:8.0.17";
            exec = "mongod --noauth";
            volumes = [
              "${my.stack.path}/mongodb/data:/data/db"
            ];
            networkAliases = [ "mongodb" ];
          };
        };

        meilisearch = {
          containerConfig = {
            image = "getmeili/meilisearch:v1.35.1";
            volumes = [
              "${my.stack.path}/meilisearch/meili_data_v1.35:/meili_data"
            ];
            environments = {
              MEILI_HOST = "http://${quadlet.alias containers.librechat-meilisearch}:7700";
              MEILI_NO_ANALYTICS = "true";
            };
            environmentFiles = [ config.sops.templates."librechat.env".path ];
            networkAliases = [ "meilisearch" ];
          };
        };

        vectordb = {
          containerConfig = {
            image = "pgvector/pgvector:0.8.0-pg15-trixie";
            volumes = [
              "${my.stack.path}/vectordb/pgdata2:/var/lib/postgresql/data"
            ];
            environments = {
              POSTGRES_DB = "mydatabase";
              POSTGRES_USER = "myuser";
            };
            environmentFiles = [ config.sops.templates."librechat.env".path ];
            networkAliases = [ "vectordb" ];
          };
        };

        rag-api = {
          containerConfig = {
            image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest@sha256:080016e3bf53648ae11c4aa347091885b47972f71638961b4e3eaee4d5105bf7";
            environments = {
              DB_HOST = quadlet.alias containers.librechat-vectordb;
              RAG_PORT = "8000";
            };
            environmentFiles = [ config.sops.templates."librechat.env".path ];
            networkAliases = [ "rag_api" ];
            autoUpdate = "registry";
          };
          dependsOn = [ "vectordb" ];
        };
      };
    };
  };
}
