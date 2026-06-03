{ config, flake, pkgs, ... }:
let
  my = config.services.my.litellm;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;

  yamlFormat = pkgs.formats.yaml { };

  # Declarative model catalog. Add/remove entries here — STORE_MODEL_IN_DB is
  # off so the DB does not silently shadow this list.
  litellmConfig =
    let
      openaiKey = "os.environ/OPENAI_API_KEY";
      anthropicKey = "os.environ/ANTHROPIC_API_KEY";
      geminiKey = "os.environ/GEMINI_API_KEY";
    in
    {
      model_list = [
        {
          model_name = "gpt-5";
          litellm_params = {
            model = "openai/gpt-5";
            api_key = openaiKey;
          };
        }
        {
          model_name = "gpt-5-mini";
          litellm_params = {
            model = "openai/gpt-5-mini";
            api_key = openaiKey;
          };
        }
        {
          model_name = "claude-sonnet-4-5";
          litellm_params = {
            model = "anthropic/claude-sonnet-4-5";
            api_key = anthropicKey;
          };
        }
        {
          model_name = "claude-opus-4-5";
          litellm_params = {
            model = "anthropic/claude-opus-4-5";
            api_key = anthropicKey;
          };
        }
        {
          model_name = "gemini-2.5-pro";
          litellm_params = {
            model = "gemini/gemini-2.5-pro";
            api_key = geminiKey;
          };
        }
        {
          model_name = "gemini-2.5-flash";
          litellm_params = {
            model = "gemini/gemini-2.5-flash";
            api_key = geminiKey;
          };
        }
      ];

      general_settings = {
        master_key = "os.environ/LITELLM_MASTER_KEY";
        database_url = "os.environ/DATABASE_URL";
      };
    };
in
{
  sops.secrets = {
    litellmMasterKey = { };
    litellmSaltKey = { };
    litellmDbPassword = { };
  };

  environment.etc."stacks/litellm/config.yaml".source =
    yamlFormat.generate "litellm-config.yaml" litellmConfig;

  sops.templates."litellm.env" = {
    restartUnits = [ (quadlet.service containers.litellm-web) ];
    content = ''
      LITELLM_MASTER_KEY=${config.sops.placeholder.litellmMasterKey}
      LITELLM_SALT_KEY=${config.sops.placeholder.litellmSaltKey}
      DATABASE_URL=postgresql://litellm:${config.sops.placeholder.litellmDbPassword}@${quadlet.alias containers.litellm-db}:5432/litellm
      STORE_MODEL_IN_DB=False
      OPENAI_API_KEY=${config.sops.placeholder.openaiKey}
      ANTHROPIC_API_KEY=${config.sops.placeholder.anthropicKey}
      GEMINI_API_KEY=${config.sops.placeholder.geminiKey}
      OPENROUTER_API_KEY=${config.sops.placeholder.openrouterKey}
    '';
  };

  sops.templates."litellm-db.env" = {
    restartUnits = [ (quadlet.service containers.litellm-db) ];
    content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder.litellmDbPassword}
    '';
  };

  services.my.litellm = {
    port = 4000;
    domain = "litellm.lab.keyruu.de";
    proxy = {
      enable = true;
      whitelist = {
        enable = true;
        people = [ "lucas" ];
      };
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        {
          path = "db-data";
          mode = "0700";
          owner = "999";
          group = "999";
        }
      ];
      network.enable = true;
      security.enable = true;

      containers = {
        web = {
          containerConfig = {
            image = "ghcr.io/berriai/litellm-database:main-v1.87.0";
            publishPorts = [ "127.0.0.1:${toString my.port}:4000" ];
            exec = "--config=/app/config.yaml --port 4000";
            volumes = [
              "/etc/stacks/litellm/config.yaml:/app/config.yaml:ro"
            ];
            environmentFiles = [ config.sops.templates."litellm.env".path ];
          };
          unitConfig."X-RestartTrigger" = [
            config.environment.etc."stacks/litellm/config.yaml".source
          ];
          dependsOn = [ "db" ];
        };

        db = {
          containerConfig = {
            image = "postgres:16.14-alpine";
            environments = {
              POSTGRES_USER = "litellm";
              POSTGRES_DB = "litellm";
            };
            environmentFiles = [ config.sops.templates."litellm-db.env".path ];
            volumes = [
              "${my.stack.path}/db-data:/var/lib/postgresql/data"
            ];
            networkAliases = [ "litellm-db" ];
            healthCmd = "pg_isready -U litellm -d litellm";
            healthInterval = "10s";
            healthTimeout = "5s";
            healthRetries = 5;
            healthStartPeriod = "30s";
          };
        };
      };
    };
  };
}
