{ config, ... }:
let
  stackPath = "/etc/stacks/rybbit";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/clickhouse-data 0755 root root"
    "d ${stackPath}/postgres-data 0755 root root"
  ];

  environment.etc."stacks/rybbit/clickhouse_config".source = ./rybbit-clickhouse;

  sops.secrets = {
    resendApiKey = { };
    rybbitBetterAuthSecret = { };
    rybbitClickhousePassword = { };
    rybbitPostgresPassword = { };
  };

  sops.templates."rybbit.env" = {
    restartUnits = [
      "rybbit-backend.service"
      "rybbit-client.service"
    ];
    content = ''
      # Domain and URL Configuration
      DOMAIN_NAME=rybbit.keyruu.de
      BASE_URL=https://rybbit.keyruu.de

      # Authentication and Security
      BETTER_AUTH_SECRET=${config.sops.placeholder.rybbitBetterAuthSecret}
      DISABLE_SIGNUP=false

      # ClickHouse Database Configuration
      CLICKHOUSE_DB=analytics
      CLICKHOUSE_USER=default
      CLICKHOUSE_PASSWORD=${config.sops.placeholder.rybbitClickhousePassword}

      # PostgreSQL Database Configuration
      POSTGRES_DB=analytics
      POSTGRES_USER=frog
      POSTGRES_PASSWORD=${config.sops.placeholder.rybbitPostgresPassword}

      # Resend API Key for email
      RESEND_API_KEY=${config.sops.placeholder.resendApiKey}

      # Next.js client configuration
      NEXT_PUBLIC_BACKEND_URL=https://rybbit.keyruu.de
      NEXT_PUBLIC_DISABLE_SIGNUP=false
    '';
  };

  virtualisation.quadlet =
    let
      # renovate: datasource=docker depName=ghcr.io/rybbit-io/rybbit-backend
      rybbitVersion = "v2.2.4";
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.rybbit.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=rybbit" ];
      };

      containers = {
        rybbit-clickhouse = {
          containerConfig = {
            # renovate: ignore
            image = "clickhouse/clickhouse-server:25.4.2";
            volumes = [
              "${stackPath}/clickhouse-data:/var/lib/clickhouse"
              "${stackPath}/clickhouse_config:/etc/clickhouse-server/config.d"
            ];
            environmentFiles = [ config.sops.templates."rybbit.env".path ];
            healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:8123/ping";
            healthInterval = "3s";
            healthTimeout = "5s";
            healthRetries = 5;
            healthStartPeriod = "10s";
            networks = [ networks.rybbit.ref ];
            networkAliases = [ "clickhouse" ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            X-RestartTrigger = [
              "${config.environment.etc."stacks/rybbit/clickhouse_config".source}"
            ];
          };
        };

        rybbit-postgres = {
          containerConfig = {
            # renovate: ignore
            image = "postgres:17.4";
            volumes = [ "${stackPath}/postgres-data:/var/lib/postgresql/data" ];
            environmentFiles = [ config.sops.templates."rybbit.env".path ];
            healthCmd = "pg_isready -U frog -d analytics";
            healthInterval = "3s";
            healthTimeout = "5s";
            healthRetries = 5;
            healthStartPeriod = "10s";
            networks = [ networks.rybbit.ref ];
            networkAliases = [ "postgres" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        rybbit-backend = {
          containerConfig = {
            image = "ghcr.io/rybbit-io/rybbit-backend:${rybbitVersion}";
            publishPorts = [ "127.0.0.1:3001:3001" ];
            environments = {
              NODE_ENV = "production";
              CLICKHOUSE_HOST = "http://clickhouse:8123";
              POSTGRES_HOST = "postgres";
              POSTGRES_PORT = "5432";
            };
            environmentFiles = [ config.sops.templates."rybbit.env".path ];
            healthCmd = "wget --no-verbose --tries=1 --spider http://127.0.0.1:3001/api/health";
            healthInterval = "3s";
            healthTimeout = "5s";
            healthRetries = 5;
            healthStartPeriod = "10s";
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
            ];
            networks = [ networks.rybbit.ref ];
            networkAliases = [ "backend" ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [
              "rybbit-clickhouse.service"
              "rybbit-postgres.service"
            ];
            Requires = [
              "rybbit-clickhouse.service"
              "rybbit-postgres.service"
            ];
          };
        };

        rybbit-client = {
          containerConfig = {
            image = "ghcr.io/rybbit-io/rybbit-client:${rybbitVersion}";
            publishPorts = [ "127.0.0.1:3002:3002" ];
            environments = {
              NODE_ENV = "production";
            };
            environmentFiles = [ config.sops.templates."rybbit.env".path ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
            ];
            networks = [ networks.rybbit.ref ];
            networkAliases = [ "client" ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [ "rybbit-backend.service" ];
            Requires = [ "rybbit-backend.service" ];
          };
        };
      };
    };

  services.caddy.virtualHosts = {
    "rybbit.keyruu.de".extraConfig = ''
      coraza_waf {
        load_owasp_crs
        directives `
          SecRuleEngine On
          Include @coraza.conf-recommended
          Include @crs-setup.conf.example
          Include @owasp_crs/*.conf
        `
      }

      reverse_proxy http://127.0.0.1:3002
      reverse_proxy /api/* http://127.0.0.1:3001
    '';
    "sorryihavetodothis.keyruu.de".extraConfig = ''
      coraza_waf {
        load_owasp_crs
        directives `
          SecRuleEngine On
          Include @coraza.conf-recommended
          Include @crs-setup.conf.example
          Include @owasp_crs/*.conf
        `
      }

      reverse_proxy http://127.0.0.1:3002
      reverse_proxy /api/* http://127.0.0.1:3001
    '';
  };
}
