vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("cfg.options")
require("cfg.keymaps")
require("cfg.autocmds")

require("cfg.treesitter")
require("lazydev").setup({})
require("cfg.blink")
require("cfg.lsp")

require("cfg.ui")
require("cfg.smart-splits")
require("cfg.editor")
require("cfg.snacks")
require("cfg.jira")

require("cfg.theme")
