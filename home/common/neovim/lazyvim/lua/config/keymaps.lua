-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("t", ";;", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.keymap.set("n", "<leader>tt", function()
  Snacks.terminal(nil, { win = {
    height = 0.25,
    wo = {
      winbar = "🐟: %{b:term_title}",
    },
  } })
end, { desc = "Open [T]erminal" })

vim.keymap.set("n", "<leader>tv", function()
  Snacks.terminal.open(nil, { split = "vertical" })
end, { desc = "Open [T]erminal [v]ertically" })

vim.keymap.set("x", "p", '"_dP', { desc = "Paste - no buffer override" })
vim.keymap.set({ "n", "x", "v" }, "<leader>y", '"+y', { desc = "Cop[y] to system clipboard" })
vim.keymap.set({ "n", "x", "v" }, "<leader>d", '"+d', { desc = "[D]elete to system clipboard" })
vim.keymap.set({ "n", "x", "v" }, "<leader>p", '"+p', { desc = "[P]aste from system clipboard" })
vim.keymap.set("n", "yc", "yygccp", { desc = "[Y]ank line, paste and [c]omment out the yanked line" })

-- rewrite word but not if its part of another word
-- vim.keymap.set(
--   "n",
--   "<leader>R",
--   [[:%s/<<C-r><C-w>>/<C-r><C-w>/gI<Left><Left><Left>]],
--   { desc = "Rewrite only word nothing else" }
-- )

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

vim.keymap.set("n", "<leader>ac", function()
  require("codecompanion").prompt("code")
end, { noremap = true, silent = true, desc = "[A]I [C]ode prompt" })

vim.keymap.set("n", "<leader>k", function()
  vim.diagnostic.open_float(nil, { focusable = false })
end, { desc = "Diagnostic float" })
