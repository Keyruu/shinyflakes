_:
{
  programs.nvf.settings.vim = {
    options = {
      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      expandtab = true;
      autoindent = true;
      smartindent = true;

      wrap = false;
      termguicolors = true;
      cursorline = true;
      scrolloff = 999;

      hlsearch = true;
      incsearch = true;

      undofile = true;
      undodir = "/home/lucas/.vim/undodir";

      clipboard = "";
    };

    visuals = {
      nvim-web-devicons.enable = true;
      indent-blankline.enable = true;
      highlight-undo.enable = true;
      nvim-cursorline.enable = false;
    };

    statusline.lualine = {
      enable = true;
      globalStatus = true;
    };

    tabline.nvimBufferline = {
      enable = true;
      setupOpts = {
        options = {
          numbers = "none";
          left_trunc_marker = "";
          right_trunc_marker = "";
          separator_style = "thin";
          # always_show_bufferline = true;
        };
      };
    };

    theme = {
      enable = false;
    };

    autopairs.nvim-autopairs.enable = true;

    autocomplete.nvim-cmp = {
      enable = true;
      setupOpts = {
        completion.completeopt = "menu,menuone,noselect";
      };
    };

    filetree.neo-tree = {
      enable = true;
      setupOpts = {
        close_if_last_window = true;
        filesystem.follow_current_file = {
          enabled = true;
          leave_dirs_open = false;
        };
      };
    };

    git = {
      enable = true;
      gitsigns.enable = true;
    };

    telescope.enable = true;

    ui = {
      borders = {
        enable = true;
        plugins = {
          nvim-cmp.enable = true;
          which-key.enable = true;
        };
      };
      colorizer.enable = true;
    };

    comments.comment-nvim.enable = true;

    binds = {
      whichKey.enable = true;
      cheatsheet.enable = false;
    };
    terminal.toggleterm = {
      enable = true; # toggleable terminal(s)
      lazygit.enable = true; # spawn LazyGit via toggleterm
    };
  };
}
