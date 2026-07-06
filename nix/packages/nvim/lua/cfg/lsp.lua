vim.diagnostic.config({
	severity_sort = true,
	underline = true,
	signs = true,
	virtual_text = { source = "if_many", spacing = 2 },
})

local lsp = vim.lsp
lsp.enable({
	"nixd",
	"nil_ls",
	"lua_ls",
	"astro",
	"gopls",
	"rust_analyzer",
	"ts_ls",
	"bashls",
	"cssls",
	"html",
	"tailwindcss",
	"jsonls",
	"helm_ls",
	"terraformls",
	"vuels",
	"astro",
	"svelte",
	"lua_ls",
	"marksman",
})

lsp.config("nixd", {
	settings = {
		nixd = {
			options = {
				nixos = { expr = '(builtins.getFlake "/home/lucas/shinyflakes").nixosConfigurations.mentat.options' },
				home_manager = {
					expr = '(builtins.getFlake "/home/lucas/shinyflakes").nixosConfigurations.muadib.options.home-manager.users.type.getSubOptions []',
				},
			},
			formatting = { command = { "nixfmt" } },
		},
	},
})
lsp.config("nil_ls", { settings = { nix = { flake = { autoArchive = true, autoEvalInputs = true } } } })

lsp.config("yamlls", {
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
})

lsp.inlay_hint.enable(true)
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		lsp.buf.format({ async = false })
	end,
})

require("trouble").setup({ auto_close = true })
