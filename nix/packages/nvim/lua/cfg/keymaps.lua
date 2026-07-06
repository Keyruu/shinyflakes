local map = require("cfg.util").map

-- terminal / window nav
map("t", ";;", "<C-\\><C-n>", "Exit terminal mode")

-- buffers
map("n", "<S-h>", ":bprevious<CR>", "Previous buffer")
map("n", "<S-l>", ":bnext<CR>", "Next buffer")
map("n", "<S-q>", function()
  local cur = vim.api.nvim_get_current_buf()
  vim.cmd("bprevious")
  vim.api.nvim_buf_delete(cur, {})
end, "Delete buffer")
map("n", "<leader>bD", ':%bdelete|edit #|normal`"<CR>', "Delete other buffers")

-- clipboard
for _, m in ipairs({ "n", "x", "v" }) do
  map(m, "<leader>y", '"+y', "Copy to system clipboard")
  map(m, "<leader>d", '"+d', "Delete to system clipboard")
  map(m, "<leader>p", '"+p', "Paste from system clipboard")
end
map("x", "p", '"_dP', "Paste without buffer override")
map("n", "yc", "yygccp", "Yank line, paste and comment yanked line")

-- file manager / outline
map("n", "-", ":Yazi<CR>", "Yazi file manager")
map("n", "gO", "<cmd>Outline<cr>", "Outline")

-- lsp / diagnostics
map("n", "K", vim.lsp.buf.hover, "LSP hover")
map("n", "gd", vim.lsp.buf.definition, "LSP definition")
map("n", "gD", vim.lsp.buf.declaration, "LSP declaration")
map("n", "gr", vim.lsp.buf.references, "LSP references")
map("n", "gi", vim.lsp.buf.implementation, "LSP implementation")
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, "Previous diagnostic")
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, "Next diagnostic")
map("n", "<leader>la", vim.lsp.buf.code_action, "LSP code action")
map("n", "<leader>ln", vim.lsp.buf.rename, "LSP rename")
map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
map("n", "<leader>lq", vim.diagnostic.setloclist, "Diagnostics loclist")
map("n", "<leader>lf", function()
  vim.lsp.buf.format({ async = true })
end, "LSP format buffer")

-- tmux-side toggles (delegate spawn/hide to tmux scripts)
map("n", "<leader>tT", "<Cmd>silent !tmux term-toggle<CR>", "Toggle bottom tmux term")
map("n", "<leader>tP", "<Cmd>silent !tmux pi-toggle<CR>", "Toggle pi in tmux pane")
map("n", "<leader>tc", ":tabclose<CR>", "Close tab")

-- markdown fenced-block jumps
map("n", "<leader>bc", "]c", "Next fenced code block")
map("n", "<leader>bp", "[c", "Previous fenced code block")
map("n", "<leader>byc", "]cyic", "Yank next fenced code block")

-- run shell command → quickfix via trouble
map("n", "<leader>rc", function()
  local cmd = vim.fn.input("Command: ", "", "shellcmd")
  vim.cmd('cgete system("' .. cmd .. '")')
  require("trouble").open("quickfix")
end, "Run command to quickfix")

-- command abbreviations (from keymaps.nix luaConfigRC.cmdAbbreviations)
vim.cmd([[cab cc CodeCompanion]])
vim.cmd([[cab tc tabclose]])
