vim.diagnostic.config({
	severity_sort = true,
	underline = true,
	signs = true,
	virtual_text = { source = "if_many", spacing = 2 },
})

-- nvim has no native helm detection; without this, chart templates get
-- ft=yaml and yamlls chokes on {{ }} syntax instead of helm_ls attaching
vim.filetype.add({
	pattern = {
		["values.*%.ya?ml"] = "yaml.helm-values",
		[".*/templates/.*%.ya?ml"] = "helm",
		[".*/templates/.*%.tpl"] = "helm",
		["helmfile.*%.ya?ml"] = "helm",
	},
})

local lsp = vim.lsp
lsp.enable({
	"nixd",
	"nil_ls",
	-- "tix",
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
	"svelte",
	"marksman",
	"yamlls",
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
lsp.config("tix", { cmd = { "tix", "lsp" }, filetypes = { "nix" } })

lsp.inlay_hint.enable(true)
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local cid = ev.data and ev.data.client_id
		if cid then
			local c = vim.lsp.get_client_by_id(cid)
			if c and c.name == "tix" then
				vim.lsp.inlay_hint.enable(false, { bufnr = ev.buf, client_id = cid })
			end
		end
	end,
})

require("trouble").setup({ auto_close = true })
