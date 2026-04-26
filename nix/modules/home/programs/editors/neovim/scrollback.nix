{
  pkgs,
  inputs,
  config,
  ...
}:
let
  kanagawa = config.programs.nvf.settings.vim.extraPlugins.kanagawa-nvim;

  scrollbackNvf = inputs.nvf.lib.neovimConfiguration {
    inherit pkgs;
    modules = [
      {
        config.vim = {
          options = {
            number = false;
            relativenumber = false;
            signcolumn = "no";
            foldenable = false;
            laststatus = 0;
            ruler = false;
            showcmd = false;
            showmode = false;
            showtabline = 0;
            foldcolumn = "0";
            wrap = true;
            linebreak = true;
            swapfile = false;
            undofile = false;
            termguicolors = true;
            scrolloff = 3;
          };

          theme.enable = false;

          extraPlugins = {
            kanagawa-nvim = kanagawa;

            baleia-nvim = {
              package = pkgs.vimPlugins.baleia-nvim;
              after = [ "kanagawa-nvim" ];
              setup = # lua
                ''
                  local baleia = require("baleia").setup({
                    line_starts_at = 1,
                    async = false,
                  })

                  local function colorize_and_jump(buf)
                    vim.bo[buf].modifiable = true
                    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

                    -- Strip OSC sequences (shell integration markers etc.)
                    -- that show up as garbage like ^[]133;A^[\
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
                    callback = function()
                      colorize_and_jump(vim.api.nvim_get_current_buf())
                    end,
                  })

                  vim.api.nvim_create_autocmd("StdinReadPost", {
                    callback = function()
                      colorize_and_jump(vim.api.nvim_get_current_buf())
                    end,
                  })
                '';
            };
          };

          clipboard = {
            enable = true;
            providers.wl-copy.enable = true;
            registers = "unnamedplus";
          };

          keymaps = [
            {
              key = "q";
              mode = "n";
              action = "<cmd>qa!<cr>";
              silent = true;
            }
            {
              key = "<Esc>";
              mode = "n";
              action = "<cmd>qa!<cr>";
              silent = true;
            }
          ];
        };
      }
    ];
  };

  nvim-scrollback = pkgs.writeShellScriptBin "nvim-scrollback" ''
    exec ${scrollbackNvf.neovim}/bin/nvim "$@"
  '';
in
{
  home.packages = [ nvim-scrollback ];

  programs.kitty.settings.scrollback_pager = "${nvim-scrollback}/bin/nvim-scrollback";
}
