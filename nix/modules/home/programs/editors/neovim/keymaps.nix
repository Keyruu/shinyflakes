_: {
  programs.nvf.settings.vim.keymaps = [
    {
      key = ";;";
      mode = "t";
      action = "<C-\\><C-n>";
      desc = "Exit terminal mode";
    }

    {
      key = "<C-h>";
      mode = "n";
      action = "<C-w>h";
      desc = "Move to left window";
      silent = true;
    }
    {
      key = "<C-h>";
      mode = "t";
      action = "<C-\\><C-n><C-w>h";
      desc = "Move to left window from terminal";
      silent = true;
    }

    {
      key = "<C-j>";
      mode = "n";
      action = "<C-w>j";
      desc = "Move to bottom window";
      silent = true;
    }
    {
      key = "<C-j>";
      mode = "t";
      action = "<C-\\><C-n><C-w>j";
      desc = "Move to bottom window from terminal";
      silent = true;
    }

    {
      key = "<C-k>";
      mode = "n";
      action = "<C-w>k";
      desc = "Move to top window";
      silent = true;
    }
    {
      key = "<C-k>";
      mode = "t";
      action = "<C-\\><C-n><C-w>k";
      desc = "Move to top window from terminal";
      silent = true;
    }

    {
      key = "<C-l>";
      mode = "n";
      action = "<C-w>l";
      desc = "Move to right window";
      silent = true;
    }
    {
      key = "<C-l>";
      mode = "t";
      action = "<C-\\><C-n><C-w>l";
      desc = "Move to right window from terminal";
      silent = true;
    }

    {
      key = "<S-h>";
      mode = "n";
      action = ":bprevious<CR>";
      desc = "Previous buffer";
      silent = true;
    }
    {
      key = "<S-l>";
      mode = "n";
      action = ":bnext<CR>";
      desc = "Next buffer";
      silent = true;
    }
    {
      key = "<leader>gg";
      mode = "n";
      action = "function() Snacks.lazygit() end";
      lua = true;
      desc = "Lazygit";
      silent = true;
    }
    {
      key = "<S-q>";
      mode = "n";
      action = ":bdelete<CR>";
      desc = "Delete buffer";
      silent = true;
    }

    {
      key = "<leader>y";
      mode = [
        "n"
        "x"
        "v"
      ];
      action = ''"+y'';
      desc = "Copy to system clipboard";
    }
    {
      key = "<leader>d";
      mode = [
        "n"
        "x"
        "v"
      ];
      action = ''"+d'';
      desc = "Delete to system clipboard";
    }
    {
      key = "<leader>p";
      mode = [
        "n"
        "x"
        "v"
      ];
      action = ''"+p'';
      desc = "Paste from system clipboard";
    }

    {
      key = "p";
      mode = "x";
      action = ''"_dP'';
      desc = "Paste without buffer override";
    }

    {
      key = "yc";
      mode = "n";
      action = "yygccp";
      desc = "Yank line, paste and comment out yanked line";
    }

    {
      key = "-";
      mode = "n";
      action = ":Yazi<CR>";
      desc = "Open Yazi file manager";
      silent = true;
    }
    {
      key = "_";
      mode = "n";
      action = ":Yazi<CR>";
      desc = "Open Yazi file manager";
      silent = true;
    }

    {
      key = "<leader><space>";
      mode = "n";
      action = "function() Snacks.picker.smart() end";
      desc = "Smart Find Files";
      silent = true;
      lua = true;
    }
    {
      key = "<leader>ff";
      mode = "n";
      action = "function() Snacks.picker.files() end";
      desc = "Smart Find Files";
      silent = true;
      lua = true;
    }
    {
      key = "<leader>fg";
      mode = "n";
      action = "function() Snacks.picker.grep() end";
      desc = "Smart Find Files";
      silent = true;
      lua = true;
    }
    {
      key = "<leader>fb";
      mode = "n";
      action = "function() Snacks.picker.buffers() end";
      desc = "Smart Find Files";
      silent = true;
      lua = true;
    }
    {
      key = "<leader>e";
      mode = "n";
      action = "function() Snacks.explorer() end";
      desc = "File Explorer";
      silent = true;
      lua = true;
    }

    {
      key = "<leader>tt";
      mode = "n";
      action = "function() Snacks.terminal() end";
      desc = "Toggle Terminal";
      silent = true;
      lua = true;
    }

    {
      key = "<leader>bc";
      mode = "n";
      action = "]c";
      desc = "Jump to next fenced code block";
    }
    {
      key = "<leader>bp";
      mode = "n";
      action = "[c";
      desc = "Jump to previous fenced code block";
    }
    {
      key = "<leader>byc";
      mode = "n";
      action = "]cyic";
      desc = "Yank inner of next fenced code block";
    }
  ];
}
