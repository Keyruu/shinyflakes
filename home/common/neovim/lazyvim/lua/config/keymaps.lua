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

-- CodeCompanion
--
-- vim.keymap.set(
--   "n",
--   "<leader>at",
--   "<CMD>CodeCompanionChat Toggle<CR>",
--   { noremap = true, silent = true, desc = "[A]I chat toggle" }
-- )
-- vim.keymap.set(
--   "n",
--   "<leader>an",
--   "<CMD>CodeCompanionChat<CR>",
--   { noremap = true, silent = true, desc = "[A]I [N]ew Augment chat" }
-- )
-- vim.keymap.set(
--   "n",
--   "<leader>aa",
--   "<CMD>CodeCompanionActions<CR>",
--   { noremap = true, silent = true, desc = "[A]I [A]ctions" }
-- )
-- vim.keymap.set("n", "<leader>ac", function()
--   require("codecompanion").prompt("code")
-- end, { noremap = true, silent = true, desc = "[A]I [C]ode prompt" })

vim.keymap.set("n", "<leader>k", function()
  vim.diagnostic.open_float(nil, { focusable = false })
end, { desc = "Diagnostic float" })

vim.keymap.set(
  "n",
  "<leader>k",
  '<cmd>lua require("kubectl").toggle({ tab = true })<cr>',
  { noremap = true, silent = true }
)

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

-- recommended mappings
-- resizing splits
-- these keymaps will also accept a range,
-- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
vim.keymap.set("n", "<C-S-h>", require("smart-splits").resize_left)
vim.keymap.set("n", "<C-S-j>", require("smart-splits").resize_down)
vim.keymap.set("n", "<C-S-k>", require("smart-splits").resize_up)
vim.keymap.set("n", "<C-S-l>", require("smart-splits").resize_right)
-- moving between splits
vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
vim.keymap.set("n", "<C-\\>", require("smart-splits").move_cursor_previous)
-- swapping buffers between windows
vim.keymap.set("n", "<leader><leader>h", require("smart-splits").swap_buf_left)
vim.keymap.set("n", "<leader><leader>j", require("smart-splits").swap_buf_down)
vim.keymap.set("n", "<leader><leader>k", require("smart-splits").swap_buf_up)
vim.keymap.set("n", "<leader><leader>l", require("smart-splits").swap_buf_right)
