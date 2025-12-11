_:
{
  programs.nvf.settings.vim.keymaps = [
    {
      key = ";;";
      mode = "t";
      action = "<C-\\><C-n>";
      desc = "Exit terminal mode";
    }

    {
      key = "<C-h>";
      mode = [
        "n"
        "t"
      ];
      action = "<C-w>h";
      desc = "Move to left window";
      silent = true;
    }
    {
      key = "<C-j>";
      mode = [
        "n"
        "t"
      ];
      action = "<C-w>j";
      desc = "Move to bottom window";
      silent = true;
    }
    {
      key = "<C-k>";
      mode = [
        "n"
        "t"
      ];
      action = "<C-w>k";
      desc = "Move to top window";
      silent = true;
    }
    {
      key = "<C-l>";
      mode = [
        "n"
        "t"
      ];
      action = "<C-w>l";
      desc = "Move to right window";
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
      key = "<leader>bd";
      mode = "n";
      action = ":bdelete<CR>";
      desc = "Delete buffer";
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
      key = "<leader>e";
      mode = "n";
      action = ":Neotree toggle<CR>";
      desc = "Toggle Neo-tree (cwd)";
      silent = true;
    }
    {
      key = "<leader>E";
      mode = "n";
      action = ":Neotree toggle<CR>";
      desc = "Toggle Neo-tree (root)";
      silent = true;
    }

    # {
    #   key = "<leader>tf";
    #   mode = "n";
    #   action = "open_fish_terminal";
    #   lua = true;
    #   desc = "Open fish terminal";
    #   silent = true;
    # }
    # {
    #   key = "<leader>tt";
    #   mode = "n";
    #   action = "open_fish_terminal_bottom";
    #   lua = true;
    #   desc = "Open terminal (bottom)";
    #   silent = true;
    # }
    # {
    #   key = "<leader>tv";
    #   mode = "n";
    #   action = "open_fish_terminal_vsplit";
    #   lua = true;
    #   desc = "Open terminal (vertical split)";
    #   silent = true;
    # }
    # {
    #   key = "<leader>tk";
    #   mode = "n";
    #   action = "open_k9s_terminal";
    #   lua = true;
    #   desc = "Open k9s terminal";
    #   silent = true;
    # }
    # {
    #   key = "<leader>tao";
    #   mode = "n";
    #   action = "open_opencode_terminal";
    #   lua = true;
    #   desc = "Open OpenCode terminal";
    #   silent = true;
    # }
    # {
    #   key = "<leader>tas";
    #   mode = "n";
    #   action = "open_opencode_sst_terminal";
    #   lua = true;
    #   desc = "Open OpenCode SST terminal";
    #   silent = true;
    # }
    # {
    #   key = "<leader>tac";
    #   mode = "n";
    #   action = "open_claude_terminal";
    #   lua = true;
    #   desc = "Open Claude Code terminal";
    #   silent = true;
    # }

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

    {
      key = "<leader>xx";
      mode = "n";
      action = ":Trouble diagnostics toggle<CR>";
      desc = "Toggle diagnostics";
      silent = true;
    }
  ];
}
