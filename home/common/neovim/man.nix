{
  lib,
  pkgs,
  ...
}:
{
  # Create the man-specific neovim config
  home.file.".config/nvim-man/init.lua".text = ''
    -- Set options
    local opts = {
      buftype = "nowrite",
      backup = false,
      modeline = false,
      shelltemp = false,
      swapfile = false,
      undofile = false,
      writebackup = false,
      virtualedit = "all",
      splitkeep = "screen",
      termguicolors = false,
      ignorecase = true,
      smartcase = true,
    }

    for k, v in pairs(opts) do
      vim.opt[k] = v
    end

    -- Use separate shada file for man pages
    vim.opt.shadafile = vim.fn.stdpath("state") .. "/shada/man.shada"

    -- Keymaps
    local keymap = vim.keymap.set
    local opts = { silent = true }

    -- Jump to tag under cursor
    keymap("n", "<CR>", "<C-]>", vim.tbl_extend("force", opts, { desc = "Jump to tag under cursor" }))

    -- Jump to previous tag in stack
    keymap("n", "<BS>", ":pop<CR>", vim.tbl_extend("force", opts, { desc = "Jump to previous tag in stack" }))
    keymap("n", "<C-Left>", ":pop<CR>", vim.tbl_extend("force", opts, { desc = "Jump to previous tag in stack" }))

    -- Jump to next tag in stack
    keymap("n", "<C-Right>", ":tag<CR>", vim.tbl_extend("force", opts, { desc = "Jump to next tag in stack" }))
  '';

  home.sessionVariables.MANPAGER = "${lib.getExe pkgs.neovim} -u ~/.config/nvim-man/init.lua +Man!";
}
