{ config, flake, ... }:
let
  stackName = "librechat";
  stackPath = "/etc/stacks/${stackName}";
  my = config.services.my.librechat;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
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
      systemd.unit = map quadlet.service [
        containers."${stackName}-api"
        containers."${stackName}-mongodb"
        containers."${stackName}-meilisearch"
        containers."${stackName}-vectordb"
        containers."${stackName}-rag-api"
      ];
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
            autoUpdate = "registry";
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [
              containers."${stackName}-mongodb".ref
              containers."${stackName}-rag-api".ref
            ];
            Requires = [
              containers."${stackName}-mongodb".ref
              containers."${stackName}-rag-api".ref
            ];
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
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        "${stackName}-rag-api" = {
          containerConfig = {
            image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest@sha256:201958505e21a1334234df6538713bac204b10d98a72d239b5318ce11f40f20b";
            environments = {
              DB_HOST = "${stackName}-vectordb";
              inherit RAG_PORT;
            };
            networks = [ networks.librechat.ref ];
            environmentFiles = [ config.sops.templates."librechat.env".path ];
            networkAliases = [ "rag_api" ];
            autoUpdate = "registry";
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [ containers."${stackName}-vectordb".ref ];
            Requires = [ containers."${stackName}-vectordb".ref ];
          };
        };
      };
    };
}
