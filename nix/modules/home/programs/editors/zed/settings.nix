{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    package-version-server
  ];

  programs.zed-editor = {
    extensions = [
      "material-icon-theme"
      "nix"
      "helm"
      "scala"
      "git-firefly"
      "dockerfile"
      "colorizer"
    ];

    userSettings = {
      tab_bar = {
        show = true;
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      theme = "Colorizer";
      edit_predictions = {
        mode = "subtle";
      };
      agent_servers = {
        claude = {
          env = {
            ANTHROPIC_BASE_URL = "http://localhost:3456";
            ANTHROPIC_AUTH_TOKEN = "dummy-key-for-router";
          };
        };
      };
      buffer_font_family = config.user.font;
      ui_font_family = config.user.font;
      terminal = {
        dock = "bottom";
        font_family = config.user.font;
      };
      icon_theme = "Material Icon Theme";
      features = {
        edit_prediction_provider = "zed";
      };
      tabs = {
        file_icons = true;
        git_status = true;
      };
      active_pane_modifiers = {
        border_size = 1;
      };
      cursor_blink = false;
      vim_mode = true;
      relative_line_numbers = "enabled";
      ui_font_size = 14;
      buffer_font_size = 14;
      vim = {
        use_system_clipboard = "on_yank";
      };
      inlay_hints = {
        enabled = true;
        toggle_on_modifiers_press = {
          control = true;
        };
      };
      file_types = {
        Helm = [
          "**/templates/**/*.tpl"
          "**/templates/**/*.yaml"
          "**/templates/**/*.yml"
          "**/helmfile.d/**/*.yaml"
          "**/helmfile.d/**/*.yml"
        ];
      };
      languages = {
        Scala = {
          language_servers = [
            "metals"
            "tailwindcss-language-server"
          ];
        };
        Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];
        };
      };
      lsp = {
        nixd = {
          settings = {
            nixd = {
              options = {
                nixos = {
                  expr = "(builtins.getFlake \"${config.home.homeDirectory}/shinyflakes\").nixosConfigurations.mentat.options";
                };
                home_manager = {
                  expr = "(builtins.getFlake \"${config.home.homeDirectory}/shinyflakes\").nixosConfigurations.muadib.options.home-manager.users.type.getSubOptions []";
                };
                tofunix = {
                  expr = "(builtins.getFlake \"${config.home.homeDirectory}/shinyflakes/tofunix\").packages.x86_64-linux.tofunix.module.options";
                };
              };
              diagnostic = {
                suppress = [ "sema-extra-with" ];
              };
            };
          };
        };
        helm_ls = {
          settings = {
            helm-ls = {
              logLevel = "info";
              yamlls = {
                enabled = true;
              };
            };
          };
        };
        yamlls = {
          initialization_options = {
            yaml = {
              schemas = {
                kubernetes = "templates/*.yaml";
                "http://json.schemastore.org/github-workflow" = ".github/workflows/*";
                "http://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
                "http://json.schemastore.org/ansible-stable-2.9" = "roles/tasks/*.{yml,yaml}";
                "http://json.schemastore.org/prettierrc" = ".prettierrc.{yml,yaml}";
                "http://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
                "http://json.schemastore.org/ansible-playbook" = "*play*.{yml,yaml}";
                "http://json.schemastore.org/chart" = "Chart.{yml,yaml}";
                "https://json.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
                "https://json.schemastore.org/gitlab-ci" = "*gitlab-ci*.{yml,yaml}";
                "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json" =
                  "*api*.{yml,yaml}";
                "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" =
                  "*docker-compose*.{yml,yaml}";
                "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" =
                  "*flow*.{yml,yaml}";
              };
            };
          };
        };

        metals = {
          settings = {
            inlayHints = {
              inferredTypes = {
                enable = true;
              };
            };
            binary = {
              arguments = [ "-Dmetals.http=on" ];
            };
            initialization_options = {
              isHttpEnabled = true;
            };
          };
        };
        tailwindcss-language-server = {
          settings = {
            includeLanguages = {
              scala = "html";
            };
            classAttributes = [
              "class"
              "className"
              "cls"
            ];
            experimental = {
              classRegex = [
                "cls\\s*:\\=\\s*['\"`]([^'\"`]*)['\"`]"
                "className\\s*:\\=\\s*['\"`]([^'\"`]*)['\"`]"
                [
                  "cls\\s*:\\=\\s*\"\"\"([\\s\\S]*?)\"\"\""
                  1
                ]
              ];
            };
          };
        };
      };
    };
  };
}
