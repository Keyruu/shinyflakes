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

-- nvim 0.12 inlay_hint passes LSP hint columns straight to
-- nvim_buf_set_extmark, which throws "Invalid 'col': out of range" when the
-- column is past EOL (e.g. nixd after a line was shortened). Upstream has no
-- clamp (verified: neovim#39772, #36318 fixed by 1f18ea1c on master, not on
-- release-0.12, and that PR doesn't clamp either). Clamp inline virt_text
-- extmarks to EOL before they reach nvim. Affects only extmarks with
-- virt_text_pos="inline", which is what inlay_hint uses.
local _orig_set_extmark = vim.api.nvim_buf_set_extmark
vim.api.nvim_buf_set_extmark = function(buf, ns, line, col, opts)
	if opts and opts.virt_text_pos == "inline" then
		local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, line, line + 1, false)
		if ok and lines[1] then
			col = math.max(0, math.min(col, #lines[1]))
		end
	end
	return _orig_set_extmark(buf, ns, line, col, opts)
end

lsp.inlay_hint.enable(true)

require("trouble").setup({ auto_close = true })
