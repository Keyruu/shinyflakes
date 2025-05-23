-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>cq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode

-- vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', ';;', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader>ef', ':Oil<CR>', { desc = 'Oil - File Browser' })
vim.keymap.set('n', '-', function()
  local _ = MiniFiles.close() or MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
  MiniFiles.reveal_cwd()
end, { desc = 'Oil [-] File Browser' })

-- vim.keymap.set('n', '<leader>t', '<cmd>ToggleTerm direction=horizontal<cr>', { desc = 'ToggleTerm' })

vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = '[Q]uit' })
vim.keymap.set('n', '<leader>Q', ':qa<CR>', { desc = '[Q]uit all' })
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = '[W]rite' })

vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help) -- LSP signature help in insert mode

vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste - no buffer override' })
vim.keymap.set({ 'n', 'x', 'v' }, '<leader>y', '"+y', { desc = 'Cop[y] to system clipboard' })
vim.keymap.set({ 'n', 'x', 'v' }, '<leader>d', '"+d', { desc = '[D]elete to system clipboard' })
vim.keymap.set({ 'n', 'x', 'v' }, '<leader>p', '"+p', { desc = '[P]aste from system clipboard' })
vim.keymap.set('n', 'yc', 'yygccp', { desc = '[Y]ank line, paste and [c]omment out the yanked line' })

vim.keymap.set('n', '<leader>?', '<cmd>lua require("which-key").show({ global = false })<cr>', { desc = 'Buffer Local Keymaps (which-key)' })
vim.keymap.set('n', '<leader>z', '<cmd>lua require("yazi").yazi()<cr>', { desc = 'Ya[z]i in cwd' })
-- vim.keymap.set('n', '<leader>s', '<cmd>noh<cr>', { desc = 'Turn off highlight until next search' })
vim.keymap.set('n', '<leader>K', '<cmd>lua require("kubectl").toggle()<cr>', { desc = 'Toggle [k]ubectl.nvim' })

-- vertically move lines when in visual mode
-- vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move Line up in visual mode' })
-- vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move Line down in visual mode' })

vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true, desc = 'Make file e[x]ecutable' })

-- rewrite word but not if its part of another word
vim.keymap.set('n', '<leader>R', [[:%s/<<C-r><C-w>>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Rewrite only word nothing else' })

-- Example mappings for usage with nvim-dap. If you don't use that, you can
-- skip these
vim.keymap.set('n', '<leader>dc', function()
  require('dap').continue()
end, { desc = '[d]ap [c]ontinue' })

vim.keymap.set('n', '<leader>dr', function()
  require('dap').repl.toggle()
end, { desc = '[d]ap [R]EPL toggle' })

vim.keymap.set('n', '<leader>dK', function()
  require('dap.ui.widgets').hover()
end, { desc = '[d]ap hover' })

vim.keymap.set('n', '<leader>dt', function()
  require('dap').toggle_breakpoint()
end, { desc = '[d]ap [t]oggle breakpoint' })

vim.keymap.set('n', '<leader>dso', function()
  require('dap').step_over()
end, { desc = '[d]ap [s]tep [o]ver' })

vim.keymap.set('n', '<leader>dsi', function()
  require('dap').step_into()
end, { desc = '[d]ap [s]tep [i]nto' })

vim.keymap.set('n', '<leader>dl', function()
  require('dap').run_last()
end, { desc = '[d]ap run [l]ast' })
