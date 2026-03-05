{
  config,
  pkgs,
  flake,
  ...
}:
let
  stackPath = "/etc/stacks/koito";
  domain = "fm.keyruu.de";
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
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
      restartUnits = [ (quadlet.service containers.koito-main) ];
      content = ''
        KOITO_DATABASE_URL=postgres://postgres:${config.sops.placeholder.koitoDbPassword}@db:5432/koitodb
        KOITO_ALLOWED_HOSTS=${domain},koito:4110
        KOITO_CORS_ALLOWED_ORIGINS=https://keyruu.de,http://localhost:4321
        KOITO_ENABLE_FULL_IMAGE_CACHE=true
      '';
    };
    "koito-db.env" = {
      restartUnits = [ (quadlet.service containers.koito-db) ];
      content = ''
        POSTGRES_DB=koitodb
        POSTGRES_USER=postgres
        POSTGRES_PASSWORD=${config.sops.placeholder.koitoDbPassword}
      '';
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) builds networks;
      src = fetchGit {
        url = "https://github.com/Keyruu/Koito.git";
        rev = "fee7fb811c8b34cb70ef7f376907c41bbb4044b4";
      };
    in
    {
      builds.koito.buildConfig = {
        workdir = "${src}";
        file = "${src}/Dockerfile";
      };

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
            image = builds.koito.ref;
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
            After = [ containers.koito-db.ref ];
            Requires = [ containers.koito-db.ref ];
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
        '';
      };
    };

    restic.backupsWithDefaults = {
      koito = {
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop ${quadlet.service containers.koito-main} ${quadlet.service containers.koito-db}";
        paths = [
          stackPath
        ];
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start ${quadlet.service containers.koito-db} ${quadlet.service containers.koito-main}";
      };
    };
  };
}
