{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    lsp = {
      enable = true;
      formatOnSave = true;
      lightbulb.enable = false;
      trouble.enable = true;
      lspSignature.enable = false;

      servers = {
        nixd = {
          cmd = [ "nixd" ];
          filetypes = [ "nix" ];
          extraOptions = {
            settings = {
              nixpkgs = {
                expr = "import <nixpkgs> {}";
              };
              formatting = {
                command = [ "nixfmt" ];
              };
              options = {
                nixos = {
                  expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.sleipnir.options";
                };
                home-manager = {
                  expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.carryall.options.home-manager.users.type.getSubOptions []";
                };
              };
            };
          };
        };

        gopls = {
          cmd = [ "gopls" ];
          filetypes = [
            "go"
            "gomod"
            "gowork"
            "gotmpl"
          ];
        };

        rust_analyzer = {
          cmd = [ "rust-analyzer" ];
          filetypes = [ "rust" ];
        };

        ts_ls = {
          cmd = [
            "typescript-language-server"
            "--stdio"
          ];
          filetypes = [
            "javascript"
            "javascriptreact"
            "typescript"
            "typescriptreact"
          ];
          extraOptions = {
            init_options = {
              typescript = {
                tsdk = "${pkgs.nodePackages.typescript}/lib/node_modules/typescript/lib";
              };
            };
          };
        };

        bashls = {
          cmd = [
            "bash-language-server"
            "start"
          ];
          filetypes = [
            "sh"
            "bash"
          ];
        };

        tailwindcss = {
          cmd = [
            "tailwindcss-language-server"
            "--stdio"
          ];
          filetypes = [
            "html"
            "css"
            "scss"
            "javascript"
            "javascriptreact"
            "typescript"
            "typescriptreact"
            "vue"
            "svelte"
          ];
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

        helm_ls = {
          cmd = [
            "helm_ls"
            "serve"
          ];
          filetypes = [ "helm" ];
        };

        terraformls = {
          cmd = [
            "terraform-ls"
            "serve"
          ];
          filetypes = [
            "terraform"
            "tf"
          ];
        };

        astro = {
          cmd = [
            "astro-ls"
            "--stdio"
          ];
          filetypes = [ "astro" ];
          extraOptions = {
            init_options = {
              typescript = {
                tsdk = "${pkgs.nodePackages.typescript}/lib/node_modules/typescript/lib";
              };
            };
          };
        };

        vuels = {
          cmd = [
            "vue-language-server"
            "--stdio"
          ];
          filetypes = [ "vue" ];
        };

        svelte = {
          cmd = [
            "svelteserver"
            "--stdio"
          ];
          filetypes = [ "svelte" ];
        };

        lua_ls = {
          cmd = [ "lua-language-server" ];
          filetypes = [ "lua" ];
        };

        marksman = {
          cmd = [
            "marksman"
            "server"
          ];
          filetypes = [
            "markdown"
            "md"
          ];
        };
      };
    };

    languages = {
      enableTreesitter = true;
      enableFormat = true;
      enableExtraDiagnostics = true;

      nix.enable = true;
      go.enable = true;
      rust.enable = true;
      ts.enable = true;
      bash.enable = true;
      css.enable = true;
      html.enable = true;
      tailwind.enable = true;
      markdown.enable = true;
    };

    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        formatters_by_ft = {
          nix = [ "nixfmt" ];
          markdown = [ "markdownlint" ];
        };
      };
    };

    treesitter.grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      regex
      ini
      yaml
      toml
      diff
      go
      rust
      javascript
      typescript
      tsx
      astro
      vue
      svelte
      lua
      json
      bash
      markdown
      markdown_inline
      helm
      terraform
    ];
  };
}
