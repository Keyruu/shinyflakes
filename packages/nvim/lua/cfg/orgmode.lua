require("orgmode").setup({
	org_agenda_files = { "~/orgfiles/**/*", "~/git/private/quackster/TODO.org" },
	org_default_notes_file = "~/orgfiles/refile.org",
})
-- Experimental LSP support
vim.lsp.enable("org")
