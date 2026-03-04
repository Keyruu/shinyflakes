{
  config,
  flake,
  pkgs,
  ...
}:
let
  stackPath = "/etc/stacks/invidious";
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

  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/companion-cache 0755 root root"
    "d ${stackPath}/postgres 0755 999 999"
    "d ${stackPath}/config 0755 root root"
  ];

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
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit =
        with containers;
        map quadlet.service [
          invidious-main
          invidious-companion
          invidious-postgres
        ];
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.invidious.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=invidious" ];
      };

      containers = {
        invidious-main = {
          containerConfig = {
            image = "quay.io/invidious/invidious:2026.01.30-48be830";
            publishPorts = [ "127.0.0.1:${toString my.port}:3000" ];
            volumes = [
              "${stackPath}/data:/data"
              "${stackPath}/config:/config"
            ];
            environmentFiles = [ config.sops.templates."invidious.env".path ];
            networks = [ networks.invidious.ref ];
            networkAliases = [ "invidious" ];
          };
          serviceConfig = {
            Restart = "on-failure";
          };
          unitConfig = with containers; {
            After = [ invidious-postgres.ref ];
            Requires = [ invidious-postgres.ref ];
          };
        };

        invidious-companion = {
          containerConfig = {
            image = "quay.io/invidious/invidious-companion:latest@sha256:2dc4de2066fc7dd9a64af3b8324dadb45f0d7c018e9484f1b4b6eaa3d43f3a41";
            environmentFiles = [ config.sops.templates."invidious-companion.env".path ];
            volumes = [
              "${stackPath}/companion-cache:/var/tmp/youtubei.js:rw"
            ];
            dropCapabilities = [ "ALL" ];
            readOnly = true;
            noNewPrivileges = true;
            networks = [ networks.invidious.ref ];
            networkAliases = [ "companion" ];
          };
          serviceConfig = {
            Restart = "on-failure";
          };
        };

        invidious-postgres = {
          containerConfig = {
            image = "docker.io/library/postgres:14";
            volumes = [
              "${stackPath}/postgres:/var/lib/postgresql/data"
              "${invidiousSrc}/config/sql:/config/sql"
              "${invidiousSrc}/docker/init-invidious-db.sh:/docker-entrypoint-initdb.d/init-invidious-db.sh"
            ];
            environments = {
              POSTGRES_DB = dbName;
              POSTGRES_USER = dbUser;
            };
            environmentFiles = [ config.sops.templates."invidious-postgres.env".path ];
            networks = [ networks.invidious.ref ];
            networkAliases = [ dbHost ];
          };
          serviceConfig = {
            Restart = "on-failure";
          };
        };
      };
    };
}
