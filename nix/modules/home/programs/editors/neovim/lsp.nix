{ config, pkgs, ... }:
{
  programs.nvf.settings.vim = {
    lsp = {
      enable = true;
      formatOnSave = true;
      lightbulb.enable = false;
      trouble.enable = true;
      lspSignature.enable = true;
      inlayHints.enable = true;

      servers = {
        nixd = {
          settings = {
            nixd = {
              options =
                let
                  flake = ''(builtins.getFlake "${config.home.homeDirectory}/shinyflakes")'';
                in
                {
                  nixos = {
                    expr = "${flake}.nixosConfigurations.mentat.options";
                  };
                  home_manager = {
                    expr = "${flake}.nixosConfigurations.muadib.options.home-manager.users.type.getSubOptions []";
                  };
                  tofunix = {
                    expr = "(builtins.getFlake \"${config.home.homeDirectory}/shinyflakes/tofunix\").packages.x86_64-linux.tofunix.module.options";
                  };
                };
            };
          };
        };
        nil = {
          settings = {
            nix = {
              flake = {
                autoArchive = true;
                autoEvalInputs = true;
              };
            };
          };
        };

        jsonls = {
          cmd = [
            "vscode-json-language-server"
            "--stdio"
          ];
          filetypes = [
            "json"
            "jsonc"
          ];
        };

        yamlls = {
          cmd = [
            "yaml-language-server"
            "--stdio"
          ];
          filetypes = [
            "yaml"
            "yml"
          ];
          extraOptions = {
            settings = {
              yaml = {
                schemas = {
                  kubernetes = "/*.yaml";
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
        };

        # astro = {
        #   cmd = [
        #     "astro-ls"
        #     "--stdio"
        #   ];
        #   filetypes = [ "astro" ];
        #   extraOptions = {
        #     init_options = {
        #       typescript = {
        #         tsdk = "${pkgs.nodePackages.typescript}/lib/node_modules/typescript/lib";
        #       };
        #     };
        #   };
        # };

        vuels = {
          cmd = [
            "vue-language-server"
            "--stdio"
          ];
          filetypes = [ "vue" ];
        };
      };
    };

    languages = {
      enableTreesitter = true;
      enableFormat = true;
      enableExtraDiagnostics = true;
      enableDAP = true;

      astro.enable = true;
      java.enable = true;
      kotlin.enable = true;
      nix = {
        enable = true;
        lsp.servers = [
          "nixd"
          "nil"
        ];
        format.type = [ "nixfmt" ];
      };
      go.enable = true;
      rust.enable = true;
      ts.enable = true;
      bash.enable = true;
      css.enable = true;
      # FIXME: superhtml 0.6.2 is broken
      html.enable = false;
      python.enable = true;
      tailwind.enable = true;
      markdown = {
        enable = true;
        extensions.render-markdown-nvim.enable = true;
      };
      yaml.enable = true;
      hcl.enable = true;
      terraform.enable = true;
      helm.enable = true;
      scala.enable = true;
      # broken
      sql.enable = false;
      svelte.enable = true;
    };

    formatter.conform-nvim = {
      enable = true;
    };

    treesitter = {
      autotagHtml = true;
      grammars = pkgs.vimPlugins.nvim-treesitter.allGrammars;
      context = {
        enable = true;
        setupOpts = {
          separator = "—";
          max_lines = 5;
        };
      };
    };
  };
}
