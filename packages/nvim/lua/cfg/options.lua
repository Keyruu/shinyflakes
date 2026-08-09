-- options (ported from settings.nix)
local o = vim.opt
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.expandtab = true
o.autoindent = true
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.wrap = false
o.termguicolors = true
o.cursorline = true
o.number = true
o.relativenumber = true
o.scrolloff = 999
o.hlsearch = true
o.incsearch = true
o.undofile = true
o.undodir = "/home/lucas/.vim/undodir"
o.clipboard = ""
o.laststatus = 3
o.splitkeep = "screen"
o.signcolumn = "yes"

-- neovim doesn't auto-create stdpath("cache"); plugins like snacks.lazygit
-- write into it, so ensure it exists at startup.
vim.fn.mkdir(vim.fn.stdpath("cache"), "p")
