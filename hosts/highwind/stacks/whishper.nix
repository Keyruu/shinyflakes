{ config, ... }:
let
  stackPath = "/etc/stacks/whishper";
in
{
  # Sops secrets for database credentials
  sops.secrets = {
    whishperDbPass = { };
  };

  # Directory creation
  systemd.tmpfiles.rules = [
    "d ${stackPath}/db/data 0770 999 999"
    "d ${stackPath}/db/logs 0770 999 999"
    "d ${stackPath}/libretranslate/data 0755 1032 root"
    "d ${stackPath}/libretranslate/cache 0755 1032 root"
    "d ${stackPath}/uploads 0755 root root"
    "d ${stackPath}/logs 0755 root root"
  ];

  # Environment template for secrets
  sops.templates."whishper.env".content = ''
    DB_USER=mongo
    DB_PASS=${config.sops.placeholder.whishperDbPass}
    MONGO_INITDB_ROOT_USERNAME=mongo
    MONGO_INITDB_ROOT_PASSWORD=${config.sops.placeholder.whishperDbPass}
  '';

  # Quadlet configuration
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.whishper.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=whishper" ];
      };

      containers = {
        whishper-mongo = {
          containerConfig = {
            image = "mongo:8.0";
            volumes = [
              "${stackPath}/db/data:/data/db"
              "${stackPath}/db/logs:/var/log/mongodb"
            ];
            environmentFiles = [ config.sops.templates."whishper.env".path ];
            networks = [ networks.whishper.ref ];
            networkAliases = [ "mongo" ];
            labels = [ "wud.watch=false" ];
            exec = [
              "--logpath"
              "/var/log/mongodb/mongod.log"
            ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        whishper-translate = {
          containerConfig = {
            image = "libretranslate/libretranslate:v1.6.5";
            volumes = [
              "${stackPath}/libretranslate/data:/home/libretranslate/.local/share"
              "${stackPath}/libretranslate/cache:/home/libretranslate/.local/cache"
            ];
            environmentFiles = [ config.sops.templates."whishper.env".path ];
            environments = {
              LT_DISABLE_WEB_UI = "True";
              LT_UPDATE_MODELS = "True";
            };
            networks = [ networks.whishper.ref ];
            networkAliases = [ "translate" ];
            labels = [
              "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"
            ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [ "quadlet-whishper-mongo.service" ];
          };
        };

        whishper-main = {
          containerConfig = {
            image = "pluja/whishper:latest";
            publishPorts = [ "127.0.0.1:8082:80" ];
            volumes = [
              "${stackPath}/uploads:/app/uploads"
              "${stackPath}/logs:/var/log/whishper"
            ];
            environmentFiles = [ config.sops.templates."whishper.env".path ];
            environments = {
              PUBLIC_INTERNAL_API_HOST = "http://127.0.0.1:80";
              PUBLIC_TRANSLATION_API_HOST = "";
              PUBLIC_API_HOST = "";
              PUBLIC_WHISHPER_PROFILE = "cpu";
              WHISPER_MODELS_DIR = "/app/models";
              UPLOAD_DIR = "/app/uploads";
              CPU_THREADS = "4";
            };
            networks = [ networks.whishper.ref ];
            networkAliases = [ "whishper" ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [
              "whishper-mongo.service"
              "whishper-translate.service"
            ];
            Requires = [
              "whishper-mongo.service"
              "whishper-translate.service"
            ];
          };
        };
      };
    };

  # Nginx reverse proxy
  services.nginx.virtualHosts."whishper.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8082";
      proxyWebsockets = true;
    };
  };
}
