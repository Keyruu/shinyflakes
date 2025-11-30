return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        astro = {},
        gopls = {},
        rust_analyzer = {},
        ts_ls = {},
        bashls = {},
        tailwindcss = {},
        jsonls = {},
        helm_ls = {},
        intelephense = {},
        zls = {},
        terraformls = {},
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                kubernetes = "/*.yaml",
                ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
                ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
                ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
                ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
                ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
                ["http://json.schemastore.org/ansible-playbook"] = "*play*.{yml,yaml}",
                ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
                ["https://json.schemastore.org/dependabot-v2"] = ".github/dependabot.{yml,yaml}",
                ["https://json.schemastore.org/gitlab-ci"] = "*gitlab-ci*.{yml,yaml}",
                ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] = "*api*.{yml,yaml}",
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",
                ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = "*flow*.{yml,yaml}",
              },
            },
          },
        },
        vuels = {},
        svelte = {},
        nixd = {
          settings = {
            nixpkgs = {
              expr = "import <nixpkgs> {}",
            },
            formatting = {
              command = "nixfmt",
            },
            options = {
              nixos = {
                expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.sleipnir.options",
              },
              ["home-manager"] = {
                expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.carryall.options.home-manager.users.type.getSubOptions []",
              },
            },
          },
        },
      },
    },
  },
}
