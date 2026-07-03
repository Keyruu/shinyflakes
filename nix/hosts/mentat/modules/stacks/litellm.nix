{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
let
  my = config.services.my.litellm;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;

  yamlFormat = pkgs.formats.yaml { };

  # Declarative model catalog. Each tag (work/private) groups providers with
  # their own API keys. Models get auto-prefixed: tag/model-name.
  # Virtual keys then scope to "work/*" or "private/*".
  model-scopes = {
    work = {
      anthropic = {
        key = "os.environ/ANTHROPIC_API_KEY_WORK";
        models = [
          "claude-opus-4-6"
          "claude-sonnet-4-6"
          "claude-opus-4-7"
          "claude-opus-4-8"
        ];
      };
      openrouter = {
        key = "os.environ/OPENROUTER_API_KEY_WORK";
        models = [
          "minimax/minimax-m3"
          "qwen/qwen3.7-plus"
          "qwen/qwen3.6-plus"
          "qwen/qwen3.6-27b"
          "qwen/qwen3.5-35b-a3b"
          "qwen/qwen3.5-27b"
          "google/gemma-4-31b-it"
          "z-ai/glm-5.2"
        ];
      };
    };

    private = {
      openrouter = {
        key = "os.environ/OPENROUTER_API_KEY_PRIVATE";
        models = [
          "qwen/qwen3.6-27b"
        ];
      };
      # Alibaba Cloud DashScope OpenAI-compatible mode. litellm uses the
      # `openai` provider prefix with a custom api_base for this endpoint.
      alibaba = {
        key = "os.environ/ALIBABA_API_KEY_PRIVATE";
        prefix = "openai";
        apiBase = "https://ws-ib38hadnx22mxl9c.eu-central-1.maas.aliyuncs.com/compatible-mode/v1";
        models = [
          "qwen3.7-plus"
          "qwen3.7-max"
          "qwen3.6-plus"
          "qwen3.6-flash"
          "qwen3.6-open-source"
        ];
      };
    };
  };

  # Expand scope definitions into litellm model_list entries.
  # Iterates scope name (work/private) → provider → model id.
  litellmConfig = {
    model_list = builtins.concatMap (
      scopeName:
      let
        scope = model-scopes.${scopeName};
      in
      builtins.concatMap (
        provName:
        let
          provider = scope.${provName};
        in
        map (modelId: {
          model_name = "${scopeName}/${modelId}";
          litellm_params = {
            model = "${provider.prefix or provName}/${modelId}";
            api_key = provider.key;
          } // lib.optionalAttrs (provider ? apiBase) {
            api_base = provider.apiBase;
          };
        }) provider.models
      ) (builtins.attrNames scope)
    ) (builtins.attrNames model-scopes);

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

  environment.etc."stacks/litellm/config.yaml".source =
    yamlFormat.generate "litellm-config.yaml" litellmConfig;

  # Long LLM completions exceed nginx's 60s default; bump proxy timeouts.
  # extraConfig is a `lines` type, so this appends to the module's whitelist block.
  services.nginx.virtualHosts.${my.domain}.locations."/".extraConfig = ''
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
  '';

  sops = {
    secrets = {
      litellmMasterKey = { };
      litellmSaltKey = { };
      litellmDbPassword = { };
      anthropicKey = { };
      openrouterKey = { };
      openrouterKeyPrivate = { };
      alibabaKey = { };
    };

    templates."litellm.env" = {
      restartUnits = [ (quadlet.service containers.litellm-web) ];
      content = ''
        LITELLM_MASTER_KEY=${config.sops.placeholder.litellmMasterKey}
        LITELLM_SALT_KEY=${config.sops.placeholder.litellmSaltKey}
        DATABASE_URL=postgresql://litellm:${config.sops.placeholder.litellmDbPassword}@${quadlet.alias containers.litellm-db}:5432/litellm
        STORE_MODEL_IN_DB=False
        ANTHROPIC_API_KEY_WORK=${config.sops.placeholder.anthropicKey}
        OPENROUTER_API_KEY_WORK=${config.sops.placeholder.openrouterKey}
        OPENROUTER_API_KEY_PRIVATE=${config.sops.placeholder.openrouterKeyPrivate}
        ALIBABA_API_KEY_PRIVATE=${config.sops.placeholder.alibabaKey}
      '';
    };

    templates."litellm-db.env" = {
      restartUnits = [ (quadlet.service containers.litellm-db) ];
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder.litellmDbPassword}
      '';
    };
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
          # alpine postgres runs as uid/gid 70, not debian's 999
          owner = "70";
          group = "70";
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
            image = "ghcr.io/berriai/litellm-database:v1.90.2";
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
