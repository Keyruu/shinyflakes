_: {
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

      laststatus = 3;
      splitkeep = "screen";
    };

    visuals = {
      nvim-web-devicons.enable = true;
      indent-blankline.enable = false;
      highlight-undo.enable = true;
      nvim-cursorline.enable = false;
    };

    statusline.lualine = {
      enable = true;
      globalStatus = true;
    };

    dashboard.dashboard-nvim = {
      enable = true;
    };

    mini = {
      tabline.enable = true;
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
      sources = {
        buffer = "[Buffer]";
        nvim-cmp = null;
        path = "[Path]";
      };
      mappings = {
        next = "<C-n>";
        previous = "<C-p>";
        confirm = "<C-y>";
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

    telescope.enable = false;

    ui = {
      borders = {
        enable = true;
        plugins = {
          nvim-cmp.enable = true;
          which-key.enable = true;
        };
      };
      colorizer.enable = true;
      noice = {
        enable = true;
        setupOpts = {
          messages.enabled = false;
        };
      };
    };

    comments.comment-nvim.enable = true;

    binds = {
      whichKey.enable = true;
      cheatsheet.enable = false;
    };
  };
}
