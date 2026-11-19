{ ... }:
{
  den.aspects.services.tranquil-pds = {
    nixos =
      { config, ... }:
      let
        my = config.services.my.tranquil-pds;
      in
      {
        sops.secrets = {
          resendApiKey = { };
          tranquilPdsJwtSecret = { };
          tranquilPdsDpopSecret = { };
          tranquilPdsMasterKey = { };
          tranquilPdsDbPassword = { };
        };

        sops.templates = {
          "tranquil-pds.env" = {
            owner = "tranquil-pds";
            restartUnits = [ "tranquil-pds.service" ];
            content = ''
              JWT_SECRET=${config.sops.placeholder.tranquilPdsJwtSecret}
              DPOP_SECRET=${config.sops.placeholder.tranquilPdsDpopSecret}
              MASTER_KEY=${config.sops.placeholder.tranquilPdsMasterKey}
              MAIL_SMARTHOST_USERNAME=resend
              MAIL_SMARTHOST_PASSWORD=${config.sops.placeholder.resendApiKey}
              DATABASE_URL=postgresql://tranquil-pds:${config.sops.placeholder.tranquilPdsDbPassword}@127.0.0.1:5432/tranquil-pds
            '';
          };

          "tranquil-pds-db.env" = {
            restartUnits = [ "tranquil-pds-db.service" ];
            content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder.tranquilPdsDbPassword}
            '';
          };
        };

        # uid/gid 70 = postgres in alpine images; the entrypoint drops to it
        # before creating $PGDATA, so a root-owned dir makes it fail.
        systemd.tmpfiles.rules = [ "d /var/lib/tranquil-pds/pg 0700 70 70 -" ];

        services.my.tranquil-pds = {
          port = 2583;
          domain = "pds.keyruu.de";
          title = "PDS";
          description = "AT Protocol Personal Data Server";
          dashboard = {
            groups = [ "admin" ];
            icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bluesky.svg";
          };
          monitor.healthPath = "/xrpc/_health";
          backup = {
            enable = true;
            paths = [ "/var/lib/tranquil-pds" ];
            systemd.unit = [
              "tranquil-pds.service"
              "tranquil-pds-db.service"
            ];
          };
        };

        services.tranquil-pds = {
          enable = true;
          environmentFiles = [ config.sops.templates."tranquil-pds.env".path ];

          settings = {
            server = {
              inherit (my) port;
              hostname = my.domain;
              host = "127.0.0.1";
              # Handles live on the bare domain, not on pds.keyruu.de.
              user_handle_domains = [ "keyruu.de" ];
              # prime is a 40 GB VPS; the 10 GiB default could fill the disk.
              max_blob_size = 1073741824;
            };

            # Password comes from DATABASE_URL in the env file; this value
            # only satisfies build-time validation (`validate --ignore-secrets`).
            database.url = "postgresql://tranquil-pds@127.0.0.1:5432/tranquil-pds";

            email = {
              from_address = "pds@lab.keyruu.de";
              from_name = "keyruu.de PDS";
              # username/password go through the env file: config validation
              # rejects a half-set credential pair and only sees the file.
              smarthost = {
                host = "smtp.resend.com";
                port = 587;
              };
            };
          };
        };

        virtualisation.quadlet.containers.tranquil-pds-db = {
          containerConfig = {
            image = "docker.io/library/postgres:18-alpine";
            publishPorts = [ "127.0.0.1:5432:5432" ];
            # postgres 18 keeps PGDATA under /var/lib/postgresql/<major>/docker
            volumes = [ "/var/lib/tranquil-pds/pg:/var/lib/postgresql" ];
            environments = {
              POSTGRES_DB = "tranquil-pds";
              POSTGRES_USER = "tranquil-pds";
            };
            environmentFiles = [ config.sops.templates."tranquil-pds-db.env".path ];
            healthCmd = "pg_isready -U tranquil-pds -d tranquil-pds";
            healthInterval = "10s";
            healthStartPeriod = "10s";
            healthRetries = 5;
            memory = "512m";
          };
        };

        systemd.services.tranquil-pds = {
          after = [ "tranquil-pds-db.service" ];
          requires = [ "tranquil-pds-db.service" ];
        };

        # No WAF: the OWASP CRS rules false-positive on xrpc JSON bodies and
        # break federation. cloudflare-only matches the proxied DNS record.
        services.caddy.virtualHosts."${my.domain}".extraConfig = ''
          import cloudflare-only
          reverse_proxy 127.0.0.1:${toString my.port}
        '';
      };
  };
}
