{
  config,
  flake,
  pkgs,
  ...
}:
let
  my = config.services.my.invidious;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
  dbName = "invidious";
  dbUser = "peter";
  dbHost = "db";
  dbPort = 5432;
  companionPort = 8282;

  companionKey = config.sops.placeholder.invidiousCompanionKey;
  dbPassword = config.sops.placeholder.invidiousDbPassword;
  hmacKey = config.sops.placeholder.invidiousHmacKey;

  invidiousSrc = pkgs.fetchFromGitHub {
    owner = "iv-org";
    repo = "invidious";
    rev = "v2.20250913.0";
    sha256 = "sha256-hRpY0nNUCHs2d2zplrS/zp5uJKIdeqc9FLnXrxkPBAs=";
  };
in
{
  sops.secrets = {
    invidiousDbPassword = { };
    invidiousCompanionKey = { };
    invidiousHmacKey = { };
  };

  sops.templates = {
    "invidious.env" = {
      restartUnits = [ (quadlet.service containers.invidious-main) ];
      content = ''
        INVIDIOUS_CONFIG=${
          builtins.toJSON {
            db = {
              dbname = dbName;
              user = dbUser;
              password = config.sops.placeholder.invidiousDbPassword;
              host = dbHost;
              port = dbPort;
            };
            check_tables = true;
            invidious_companion = [
              { private_url = "http://companion:${toString companionPort}/companion"; }
            ];
            invidious_companion_key = companionKey;
            hmac_key = hmacKey;
          }
        }
      '';
    };
    "invidious-companion.env" = {
      restartUnits = [ (quadlet.service containers.invidious-companion) ];
      content = ''
        SERVER_SECRET_KEY=${companionKey}
      '';
    };
    "invidious-postgres.env" = {
      restartUnits = [ (quadlet.service containers.invidious-postgres) ];
      content = ''
        POSTGRES_PASSWORD=${dbPassword}
      '';
    };
  };

  services.my.invidious = {
    port = 3009;
    domain = "invidious.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        "data"
        "companion-cache"
        {
          path = "postgres";
          mode = "0755";
          owner = "999";
          group = "999";
        }
        "config"
      ];
      network.enable = true;
      main = "main";
      internalPort = 3000;
      security.enable = false;

      containers = {
        main = {
          containerConfig = {
            image = "quay.io/invidious/invidious:2026.01.30-48be830";
            volumes = [
              "${my.stack.path}/data:/data"
              "${my.stack.path}/config:/config"
            ];
            environmentFiles = [ config.sops.templates."invidious.env".path ];
            networkAliases = [ "invidious" ];
          };
          dependsOn = [ "postgres" ];
        };

        companion = {
          containerConfig = {
            image = "quay.io/invidious/invidious-companion:latest@sha256:2dc4de2066fc7dd9a64af3b8324dadb45f0d7c018e9484f1b4b6eaa3d43f3a41";
            environmentFiles = [ config.sops.templates."invidious-companion.env".path ];
            volumes = [
              "${my.stack.path}/companion-cache:/var/tmp/youtubei.js:rw"
            ];
            networkAliases = [ "companion" ];
          };
        };

        postgres = {
          containerConfig = {
            image = "docker.io/library/postgres:14";
            volumes = [
              "${my.stack.path}/postgres:/var/lib/postgresql/data"
              "${invidiousSrc}/config/sql:/config/sql"
              "${invidiousSrc}/docker/init-invidious-db.sh:/docker-entrypoint-initdb.d/init-invidious-db.sh"
            ];
            environments = {
              POSTGRES_DB = dbName;
              POSTGRES_USER = dbUser;
            };
            environmentFiles = [ config.sops.templates."invidious-postgres.env".path ];
            networkAliases = [ dbHost ];
          };
        };
      };
    };
  };
}
