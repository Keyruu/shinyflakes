_: {
  programs.nvf.settings.vim = {
    keymaps = [
      {
        key = ";;";
        mode = "t";
        action = "<C-\\><C-n>";
        desc = "Exit terminal mode";
      }

      # C-h/j/k/l: navigate nvim splits and hand off to tmux at the edge via
      # smart-splits.nvim. <Cmd> keeps modes clean so the same mapping works
      # in normal and terminal mode without leaking keystrokes.
      {
        key = "<C-h>";
        mode = [
          "n"
          "t"
          "i"
        ];
        action = "<Cmd>SmartCursorMoveLeft<CR>";
        desc = "Window/pane left";
        silent = true;
      }

      {
        key = "<C-j>";
        mode = [
          "n"
          "t"
          "i"
        ];
        action = "<Cmd>SmartCursorMoveDown<CR>";
        desc = "Window/pane down";
        silent = true;
      }

      {
        key = "<C-k>";
        mode = [
          "n"
          "t"
          "i"
        ];
        action = "<Cmd>SmartCursorMoveUp<CR>";
        desc = "Window/pane up";
        silent = true;
      }

      {
        key = "<C-l>";
        mode = [
          "n"
          "t"
          "i"
        ];
        action = "<Cmd>SmartCursorMoveRight<CR>";
        desc = "Window/pane right";
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
        action = ''
          function()                                                                          
            local current_buf = vim.api.nvim_get_current_buf()                                         
            vim.cmd('bprevious')
            vim.api.nvim_buf_delete(current_buf, {})                                                   
           end
        '';
        lua = true;
        desc = "Delete buffer";
        silent = true;
      }
      {
        key = "<leader>bD";
        mode = "n";
        action = '':%bdelete|edit #|normal`"<CR>'';
        desc = "Delete all other buffers except the current one";
        silent = true;
      }
      {
        key = "<leader>,";
        mode = "n";
        action = "function() Snacks.picker.buffers() end";
        desc = "Buffers";
        silent = true;
        lua = true;
      }
      {
        key = "<leader>/";
        mode = "n";
        action = "function() Snacks.picker.grep() end";
        desc = "Grep";
        silent = true;
        lua = true;
      }
      {
        key = "<leader>:";
        mode = "n";
        action = "function() Snacks.picker.command_history() end";
        desc = "Command History";
        silent = true;
        lua = true;
      }
      {
        key = "<leader>n";
        mode = "n";
        action = "function() Snacks.picker.notifications() end";
        desc = "Notification History";
        silent = true;
        lua = true;
      }
      {
        key = "<leader>,";
        mode = "n";
        action = "function() Snacks.picker.buffers() end";
        desc = "Buffers";
        silent = true;
        lua = true;
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
        action = # lua
          ''
            function() 
              Snacks.explorer({ 
                hidden = true, 
                auto_close = true, 
                layout = { preset = "default", preview = true } 
              }) 
            end
          '';
        desc = "Open Snacks.explorer)";
        silent = true;
        lua = true;
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
        action = "function() Snacks.picker.smart({ hidden = true }) end";
        desc = "Smart Find Files";
        silent = true;
        lua = true;
      }
      {
        key = "<leader>ff";
        mode = "n";
        action = "function() Snacks.picker.files({ hidden = true }) end";
        desc = "Smart Find Files";
        silent = true;
        lua = true;
      }
      {
        key = "<leader>fg";
        mode = "n";
        action = "function() Snacks.picker.grep({ hidden = true }) end";
        desc = "Smart Find Files";
        silent = true;
        lua = true;
      }
      {
        key = "<leader>fb";
        mode = "n";
        action = "function() Snacks.picker.buffers({ hidden = true }) end";
        desc = "Smart Find Files";
        silent = true;
        lua = true;
      }
      {
        key = "<leader>e";
        mode = "n";
        action = "function() Snacks.explorer({ hidden = true, auto_close = true }) end";
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
        key = "<leader>tT";
        mode = "n";
        # Delegates to the tmux-side `prefix B` toggle so spawn/hide/restore
        # behavior matches and the pane is tagged with @is_nvim_term.
        action = "<Cmd>silent !tmux term-toggle<CR>";
        desc = "Toggle bottom tmux term";
        silent = true;
      }
      {
        key = "<leader>tp";
        mode = "n";
        action = # lua
          ''
            function()
              Snacks.terminal("pi", {
                win = {
                  position = "right",
                  width = 0.4,
                },
              })
            end
          '';
        desc = "Toggle Pi Agent Terminal";
        silent = true;
        lua = true;
      }
      {
        key = "<leader>tP";
        mode = "n";
        # Delegates to the tmux-side `prefix P` toggle (@is_pi tagged pane).
        action = "<Cmd>silent !tmux pi-toggle<CR>";
        desc = "Toggle pi in tmux pane";
        silent = true;
      }

      {
        key = "<leader>tc";
        mode = "n";
        action = ":tabclose<CR>";
        desc = "Close Tab";
        silent = true;
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

      {
        key = "<C-a>";
        mode = [
          "n"
          "v"
        ];
        action = "<cmd>CodeCompanionActions<cr>";
        desc = "Code Companion Actions";
        silent = true;
        noremap = true;
      }
      {
        key = "<leader>a";
        mode = [
          "n"
          "v"
        ];
        action = "<cmd>CodeCompanionChat Toggle<cr>";
        desc = "Toggle Code Companion Chat";
        silent = true;
        noremap = true;
      }
      {
        key = "ga";
        mode = "v";
        action = "<cmd>CodeCompanionChat Add<cr>";
        desc = "Add to Code Companion Chat";
        silent = true;
        noremap = true;
      }
      {
        key = "gO";
        mode = "n";
        action = "<cmd>Outline<cr>";
        desc = "Show outline";
        silent = true;
        noremap = true;
      }
      {
        key = "gd";
        mode = "n";
        action = "vim.lsp.buf.definition";
        desc = "Go to definition";
        silent = true;
        noremap = true;
        lua = true;
      }

      {
        key = "<leader>rc";
        mode = "n";
        action = # lua
          ''
            function()
              local command = vim.fn.input("Command: ", "", "shellcmd")
              vim.cmd('cgete system("' .. command ..'")')
              require('trouble').open('quickfix')
            end
          '';
        desc = "Toggle Pi Agent Terminal";
        silent = true;
        lua = true;
      }
    ];
    luaConfigRC = {
      cmdAbbreviations = # lua
        ''
          vim.cmd([[cab cc CodeCompanion]])
          vim.cmd([[cab tc tabclose]])
        '';
      terminalInactiveBackground = # lua
        ''
          -- Terminal buffers paint their own background via escape sequences,
          -- which overrides NormalNC. We fix this by setting winhighlight on
          -- terminal windows so inactive ones use NormalNC for Normal too.
          local function update_terminal_highlights()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_is_valid(win) then
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].buftype == "terminal" then
                  local is_focused = (win == vim.api.nvim_get_current_win())
                  vim.api.nvim_set_option_value(
                    "winhighlight",
                    is_focused and "" or "Normal:NormalNC",
                    { win = win }
                  )
                end
              end
            end
          end

          -- Core window movement events
          vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave", "TermOpen", "BufWinEnter" }, {
            callback = update_terminal_highlights,
          })

          -- When a float/window closes, focus returns but WinEnter may not re-fire
          -- for the already-focused window. Use vim.schedule since window state
          -- isn't settled yet when WinClosed fires.
          vim.api.nvim_create_autocmd({ "WinClosed" }, {
            callback = function() vim.schedule(update_terminal_highlights) end,
          })

          -- Tab switches and focus changes
          vim.api.nvim_create_autocmd({ "TabEnter", "FocusGained", "BufEnter" }, {
            callback = update_terminal_highlights,
          })
        '';
      equalizeOnResize = # lua
        ''
          vim.api.nvim_create_autocmd("VimResized", {
            callback = function() vim.cmd("wincmd =") end,
          })
        '';
    };
  };
}
