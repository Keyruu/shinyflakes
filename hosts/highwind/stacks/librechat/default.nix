{config, ...}: let
  stackName = "librechat";
  stackPath = "/etc/stacks/${stackName}";
in {
  systemd.tmpfiles.rules = [
    "d ${stackPath}/pgdata 0770 root root"
    "d ${stackPath}/model-cache 0770 root root"
  ];

  virtualisation.quadlet = let
    RAG_PORT = "8000";
    inherit (config.virtualisation.quadlet) networks;
  in {
    networks.librechat = {
      networkConfig = {
        driver = "bridge";
      };
    };

    containers = {
      "${stackName}-api" = {
        containerConfig = {
          containerName = "${stackName}-api";
          image = "ghcr.io/danny-avila/librechat-dev-api:latest";
          publishPorts = [ "3080:3080" ];
          extraHosts = [ "host.docker.internal:host-gateway" ];
          volumes = [
            "${stackPath}/api/librechat.yaml:/app/librechat.yaml"
            "${stackPath}/api/images:/app/client/public/images"
            "${stackPath}/api/uploads:/app/uploads"
            "${stackPath}/api/logs:/app/api/logs"
          ];
          environment = {
            HOST = "0.0.0.0";
            NODE_ENV = "production";
            MONGO_URI = "mongodb://mongodb:27017/LibreChat";
            MEILI_HOST = "http://meilisearch:7700";
            RAG_PORT = RAG_PORT;
            RAG_API_URL = "http://rag_api:" + RAG_PORT;
          };
          networks = [ networks.librechat ];
          environmentFiles = [ config.sops.secrets.librechatEnv.path ];
        };
        serviceConfig = {
          Restart = "always";
        };
        unitConfig = {
          After = [ "${stackName}-mongodb.service" "${stackName}-rag-api.service" ];
          Requires = [ "${stackName}-mongodb.service" "${stackName}-rag-api.service" ];
        };
      };

      "${stackName}-mongodb" = {
        containerConfig = {
          containerName = "${stackName}-mongodb";
          image = "mongo";
          command = "mongod --noauth";
          volumes = [
            "${stackPath}/mongodb/data-node:/data/db"
          ];
          networks = [ networks.librechat ];
          networkAliases = [ "mongodb" ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      "${stackName}-meilisearch" = {
        containerConfig = {
          containerName = "${stackName}-meilisearch";
          image = "getmeili/meilisearch:v1.12.3";
          volumes = [
            "${stackPath}/meilisearch/meili_data_v1.12:/meili_data"
          ];
          environment = {
            MEILI_HOST = "http://meilisearch:7700";
            MEILI_NO_ANALYTICS = "true";
          };
          networks = [ networks.librechat ];
          environmentFiles = [ config.sops.secrets.librechatEnv.path ];
          networkAliases = [ "meilisearch" ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      "${stackName}-vectordb" = {
        containerConfig = {
          containerName = "${stackName}-vectordb";
          image = "ankane/pgvector:latest";
          volumes = [
            "${stackPath}/vectordb/pgdata2:/var/lib/postgresql/data"
          ];
          environment = {
            POSTGRES_DB = "mydatabase";
            POSTGRES_USER = "myuser";
          };
          environmentFiles = [ config.sops.secrets.librechatVectordbEnv.path ];
          networks = [ networks.librechat ];
          networkAliases = [ "vectordb" ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      "${stackName}-rag-api" = {
        containerConfig = {
          containerName = "${stackName}-rag-api";
          image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest";
          environment = {
            DB_HOST = "${stackName}-vectordb";
            RAG_PORT = RAG_PORT;
          };
          networks = [ networks.librechat ];
          environmentFiles = [ config.sops.secrets.librechatEnv.path ];
          networkAliases = [ "rag_api" ];
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
