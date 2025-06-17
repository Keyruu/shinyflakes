-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("t", ";;", "<C-\\><C-n>", { desc = "Exit terminal mode" })

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

-- vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

vim.keymap.set(
  "n",
  "<leader>at",
  "<CMD>CodeCompanionChat Toggle<CR>",
  { noremap = true, silent = true, desc = "[A]I chat toggle" }
)
vim.keymap.set(
  "n",
  "<leader>an",
  "<CMD>CodeCompanionChat<CR>",
  { noremap = true, silent = true, desc = "[A]I [N]ew Augment chat" }
)
vim.keymap.set(
  "n",
  "<leader>aa",
  "<CMD>CodeCompanionActions<CR>",
  { noremap = true, silent = true, desc = "[A]I [A]ctions" }
)
vim.keymap.set("n", "<leader>ac", function()
  require("codecompanion").prompt("code")
end, { noremap = true, silent = true, desc = "[A]I [C]ode prompt" })

vim.keymap.set("n", "<leader>k", function()
  vim.diagnostic.open_float(nil, { focusable = false })
end, { desc = "Diagnostic float" })

-- Keymaps for navigating and yanking FENCED code blocks (e.g., in Markdown)
vim.keymap.set("n", "<leader>bc", "]c", { noremap = true, silent = true, desc = "Jump to next fenced [C]ode block" })
vim.keymap.set(
  "n",
  "<leader>bp",
  "[c",
  { noremap = true, silent = true, desc = "Jump to previous fenced [C]ode block" }
)
vim.keymap.set(
  "n",
  "<leader>byc",
  "]cyic",
  { noremap = true, silent = true, desc = "[Y]ank inner of next fenced [C]ode block" }
)

vim.keymap.del({ "n", "t" }, "<C-/>")
