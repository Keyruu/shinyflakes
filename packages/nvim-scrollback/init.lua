-- Scrollback viewer for zellij (EditScrollback ansi=true, file arg) and kitty
-- (scrollback_pager, stdin): baleia turns raw ANSI escapes into highlights,
-- OSC shell-integration sequences are stripped first, then the buffer is
-- locked read-only and the view jumped to the bottom. Isolated config dir, so
-- the main nvim setup is untouched.
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"
vim.opt.foldenable = false
vim.opt.laststatus = 0
vim.opt.ruler = false
vim.opt.showcmd = false
vim.opt.showmode = false
vim.opt.showtabline = 0
vim.opt.foldcolumn = "0"
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.swapfile = false
vim.opt.undofile = false
vim.opt.termguicolors = true
vim.opt.scrolloff = 3
vim.opt.clipboard = "unnamedplus"

require("kanagawa").setup({ transparent = true })
vim.cmd.colorscheme("kanagawa")

local baleia = require("baleia").setup({ line_starts_at = 1, async = false })

local function colorize_and_jump(buf)
  vim.bo[buf].modifiable = true
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  -- Strip OSC sequences (shell-integration markers etc.) that leak in as
  -- garbage alongside the ANSI color codes from ansi=true / kitty dumps.
  for i, line in ipairs(lines) do
    lines[i] = line:gsub("\27%]%d+;[^\27]*\27\\", "")
                    :gsub("\27%][^\007]*\007", "")
  end
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  baleia.once(buf)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.cmd("normal! G")
end

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function() colorize_and_jump(vim.api.nvim_get_current_buf()) end,
})
vim.api.nvim_create_autocmd("StdinReadPost", {
  callback = function() colorize_and_jump(vim.api.nvim_get_current_buf()) end,
})

vim.keymap.set("n", "q", "<cmd>qa!<cr>", { silent = true })
vim.keymap.set("n", "<Esc>", "<cmd>qa!<cr>", { silent = true })
