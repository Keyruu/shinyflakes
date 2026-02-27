{ config, pkgs, ... }:
let
  stackPath = "/etc/stacks/koito";
  domain = "fm.keyruu.de";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/db 0755 999 999"
  ];

  sops.secrets = {
    koitoDbPassword = { };
  };

  sops.templates = {
    "koito-main.env" = {
      restartUnits = [ "koito-main.service" ];
      content = ''
        KOITO_DATABASE_URL=postgres://postgres:${config.sops.placeholder.koitoDbPassword}@db:5432/koitodb
        KOITO_ALLOWED_HOSTS=${domain},koito:4110
        KOITO_CORS_ALLOWED_ORIGINS=https://keyruu.de
      '';
    };
    "koito-db.env" = {
      restartUnits = [ "koito-db.service" ];
      content = ''
        POSTGRES_DB=koitodb
        POSTGRES_USER=postgres
        POSTGRES_PASSWORD=${config.sops.placeholder.koitoDbPassword}
      '';
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.koito.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=koito" ];
      };

      containers = {
        koito-db = {
          containerConfig = {
            image = "postgres:16";
            volumes = [ "${stackPath}/db:/var/lib/postgresql/data" ];
            environmentFiles = [ config.sops.templates."koito-db.env".path ];
            healthCmd = "pg_isready -U postgres -d koitodb";
            healthInterval = "3s";
            healthTimeout = "5s";
            healthRetries = 5;
            healthStartPeriod = "10s";
            networks = [ networks.koito.ref ];
            networkAliases = [ "db" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        koito-main = {
          containerConfig = {
            image = "gabehf/koito:v0.1.7";
            publishPorts = [ "127.0.0.1:4110:4110" ];
            volumes = [ "${stackPath}/data:/etc/koito" ];
            environmentFiles = [ config.sops.templates."koito-main.env".path ];
            networks = [ networks.koito.ref ];
            networkAliases = [ "koito" ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [ "koito-db.service" ];
            Requires = [ "koito-db.service" ];
          };
        };
      };
    };

  services = {
    caddy.virtualHostsWithDefaults = {
      "${domain}" = {
        extraConfig = ''
          import cloudflare-only
          reverse_proxy http://127.0.0.1:4110

          header Access-Control-Allow-Origin "https://keyruu.de"
        '';
      };
    };

    restic.backupsWithDefaults = {
      koito = {
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop koito-*";
        paths = [
          stackPath
        ];
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start koito-* --all";
      };
    };
  };
}
