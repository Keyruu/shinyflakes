{
  config,
  flake,
  ...
}:
let
  my = config.services.my.rybbit;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    resendApiKey = { };
    rybbitBetterAuthSecret = { };
    rybbitClickhousePassword = { };
    rybbitPostgresPassword = { };
  };

  sops.templates."rybbit.env" = {
    restartUnits =
      with containers;
      map quadlet.service [
        rybbit-backend
        rybbit-client
      ];
    content = ''
      DOMAIN_NAME=rybbit.keyruu.de
      BASE_URL=https://rybbit.keyruu.de

      BETTER_AUTH_SECRET=${config.sops.placeholder.rybbitBetterAuthSecret}
      DISABLE_SIGNUP=false

      CLICKHOUSE_DB=analytics
      CLICKHOUSE_USER=default
      CLICKHOUSE_PASSWORD=${config.sops.placeholder.rybbitClickhousePassword}

      POSTGRES_DB=analytics
      POSTGRES_USER=frog
      POSTGRES_PASSWORD=${config.sops.placeholder.rybbitPostgresPassword}

      RESEND_API_KEY=${config.sops.placeholder.resendApiKey}

      NEXT_PUBLIC_BACKEND_URL=https://rybbit.keyruu.de
      NEXT_PUBLIC_DISABLE_SIGNUP=false
    '';
  };

  environment.etc."stacks/rybbit/clickhouse_config".source = ./rybbit-clickhouse;

  services.my.rybbit = {
    port = 3002;
    domain = "rybbit.keyruu.de";
    proxy.enable = false;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        "clickhouse-data"
        "postgres-data"
      ];
      network.enable = true;

      containers = {
        clickhouse = {
          containerConfig = {
            image = "clickhouse/clickhouse-server:25.4.2";
            volumes = [
              "${my.stack.path}/clickhouse-data:/var/lib/clickhouse"
              "${config.environment.etc."stacks/rybbit/clickhouse_config".source}:/etc/clickhouse-server/config.d"
            ];
            environmentFiles = [ config.sops.templates."rybbit.env".path ];
            healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:8123/ping";
            healthInterval = "3s";
            healthTimeout = "5s";
            healthRetries = 5;
            healthStartPeriod = "10s";
            networkAliases = [ "clickhouse" ];
          };
          unitConfig = {
            X-RestartTrigger = [
              "${config.environment.etc."stacks/rybbit/clickhouse_config".source}"
            ];
          };
        };

        postgres = {
          containerConfig = {
            image = "postgres:17.4";
            volumes = [ "${my.stack.path}/postgres-data:/var/lib/postgresql/data" ];
            environmentFiles = [ config.sops.templates."rybbit.env".path ];
            healthCmd = "pg_isready -U frog -d analytics";
            healthInterval = "3s";
            healthTimeout = "5s";
            healthRetries = 5;
            healthStartPeriod = "10s";
            networkAliases = [ "postgres" ];
          };
        };

        backend = {
          containerConfig = {
            image = "ghcr.io/rybbit-io/rybbit-backend:v2.4.0";
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
            networkAliases = [ "backend" ];
          };
          dependsOn = [
            "clickhouse"
            "postgres"
          ];
        };

        client = {
          containerConfig = {
            image = "ghcr.io/rybbit-io/rybbit-client:v2.4.0";
            publishPorts = [ "127.0.0.1:3002:3002" ];
            environments = {
              NODE_ENV = "production";
            };
            environmentFiles = [ config.sops.templates."rybbit.env".path ];
            networkAliases = [ "client" ];
          };
          dependsOn = [ "backend" ];
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

          # disable RCE rule for /api/track (blog URL paths in json.pathname look like unix commands)
          SecRule REQUEST_URI "@beginsWith /api/track" \
            "id:1004,\
            phase:1,\
            pass,\
            nolog,\
            ctl:ruleRemoveById=932260,\
            ctl:ruleRemoveById=934110"

          Include @coraza.conf-recommended
          Include @crs-setup.conf.example
          Include @owasp_crs/*.conf

          SecRuleRemoveById 949110
          SecRuleRemoveById 932370
          SecRuleRemoveById 911100
          SecRuleRemoveById 920420
          SecRuleRemoveById 200002
          SecRuleRemoveById 200003
        `
      }
      import cloudflare-only
      reverse_proxy http://127.0.0.1:${toString my.port}
    '';

    "sorryihavetodothis.keyruu.de".extraConfig = ''
      import coraza-waf
      import cloudflare-only
      reverse_proxy /api/* http://127.0.0.1:3001
      reverse_proxy http://127.0.0.1:3002
    '';
  };
}
