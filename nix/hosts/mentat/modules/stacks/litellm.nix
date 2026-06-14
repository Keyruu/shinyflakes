{
  config,
  flake,
  pkgs,
  ...
}:
let
  my = config.services.my.litellm;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;

  yamlFormat = pkgs.formats.yaml { };

  # Declarative model catalog. Add/remove entries here — STORE_MODEL_IN_DB is
  # off so the DB does not silently shadow this list.
  litellmConfig =
    let
      anthropicKey = "os.environ/ANTHROPIC_API_KEY";
      openrouterKey = "os.environ/OPENROUTER_API_KEY";

      anthropicModel = id: {
        model_name = id;
        litellm_params = {
          model = "anthropic/${id}";
          api_key = anthropicKey;
        };
      };
      openrouterModel = id: {
        model_name = id;
        litellm_params = {
          model = "openrouter/${id}";
          api_key = openrouterKey;
        };
      };
    in
    {
      model_list = [
        (anthropicModel "claude-opus-4-6")
        (anthropicModel "claude-sonnet-4-6")
        (anthropicModel "claude-opus-4-7")
        (anthropicModel "claude-opus-4-8")

        (openrouterModel "minimax/minimax-m3")
        (openrouterModel "qwen/qwen3.7-plus")
        (openrouterModel "qwen/qwen3.6-plus")
        (openrouterModel "qwen/qwen3.5-35b-a3b")
        (openrouterModel "qwen/qwen3.5-27b")
        {
          model_name = "qwen/qwen3.6-27b";
          litellm_params = {
            model = "openrouter/qwen/qwen3.6-27b";
            api_key = openrouterKey;
          };
          model_info = {
            input_cost_per_token = 0.00000029;
            output_cost_per_token = 0.00000320;
          };
        }
        {
          model_name = "google/gemma-4-31b-it";
          litellm_params = {
            model = "openrouter/google/gemma-4-31b-it";
            api_key = openrouterKey;
          };
          model_info = {
            input_cost_per_token = 0.00000012;
            output_cost_per_token = 0.00000037;
          };
        }
      ];

      general_settings = {
        master_key = "os.environ/LITELLM_MASTER_KEY";
        database_url = "os.environ/DATABASE_URL";
      };

      # openrouter (and others) reject unknown OpenAI params like
      # reasoning_effort. Drop them instead of failing the request.
      litellm_settings = {
        drop_params = true;
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
      ANTHROPIC_API_KEY=${config.sops.placeholder.anthropicKey}
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
          security = {
            readOnlyRootFilesystem = false;
          };
          containerConfig = {
            image = "ghcr.io/berriai/litellm-database:v1.89.0";
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
          security = {
            dropAllCapabilities = true;
            readOnlyRootFilesystem = false;
          };
          containerConfig = {
            image = "postgres:16.14-alpine";
            addCapabilities = [
              "CHOWN"
              "FOWNER"
              "DAC_OVERRIDE"
              "SETUID"
              "SETGID"
            ];
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
