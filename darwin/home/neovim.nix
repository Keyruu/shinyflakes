{ pkgs, username, ... }: {
  home.packages = with pkgs; [
    alejandra
  ];

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    opts = {
      autoindent = true;
      number = true;
      relativenumber = true;
      ignorecase = true;
      smartcase = true;
      splitright = true;
      splitbelow = true;
      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      scrolloff = 8;
      expandtab = true;
      smartindent = true;
      wrap = false;
      hlsearch = true;
      incsearch = true;
      termguicolors = true;
      cursorline = true;
      signcolumn = "yes";
      backup = false;
      swapfile = false;
      undofile = true;
      undodir = "/Users/${username}/.vim/undodir";
    };

    files = {
      "ftplugin/sh.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
      "ftplugin/markdown.lua" = {
        opts = {
          wrap = true;
          breakindent = true;
          linebreak = true;
        };
      };
    };

    colorschemes.ayu.enable = true;
    # highlightOverride = {
    #   Normal.bg = "none";
    #   NormalFloat.bg = "none";
    #   WinSeparator = {
    #     bg = "none";
    #     fg = "#eaeaea";
    #   };
    #   VirtColumn.fg = "#000000";
    #   SignColumn.bg = "none";
    #   Pmenu.bg = "none";
    # };

    #    autoCmd = [
    #      {
    #        event = [ "TextYankPost" ];
    #        desc = "Highlight when yanking (copying) text";
    #        callback = ''
    #          function()
    #            vim.highlight.on_yank()
    #          end
    #        '';
    #      }
    #    ];

    globals.mapleader = " ";
    keymaps = [
      {
        action = ":CHADopen<CR>";
        key = "<leader>ef";
        mode = "n";
      }
      {
        action = "<cmd>ToggleTerm<cr>";
        key = "<leader>t";
        mode = "n";
      }
      {
        action = "<C-\\><C-n>";
        key = "<Esc><Esc>";
        mode = "t";
      }
      {
        action = ":q<CR>";
        key = "<leader>q";
        mode = "n";
        options = {
          desc = "Quit";
        };
      }
      {
        action = ":w<CR>";
        key = "<leader>w";
        mode = "n";
      }
      {
        action = "<cmd>LazyGit<CR>";
        key = "<leader>lg";
        mode = "n";
        options = {
          desc = "LazyGit";
        };
      }
      {
        # this is here because it needs insert mode
        action.__raw = "vim.lsp.buf.signature_help";
        key = "<C-h>";
        mode = "i";
      }
      {
        # don't override buffer when pasting
        action = ''"_dP'';
        key = "p";
        mode = "x";
      }
      {
        # copy to system clipboard
        action = ''"+y'';
        key = "<leader>y";
        mode = [ "n" "x" "v" ];
        options = {
          desc = "Copy to system clipboard";
        };
      }
      {
        # delete to system clipboard
        action = ''"+d'';
        key = "<leader>d";
        mode = [ "n" "x" "v" ];
        options = {
          desc = "Delete to system clipboard";
        };
      }
      {
        # delete to system clipboard
        action = ''"+p'';
        key = "<leader>p";
        mode = [ "n" "x" "v" ];
        options = {
          desc = "Paste from system clipboard";
        };
      }
      {
        # no macro menu
        action = "<nop>";
        key = "q";
        mode = "n";
      }
      # move between windows with ctrl hjkl
      {
        action = "<C-w>h";
        key = "<C-h>";
        mode = "n";
      }
      {
        action = "<C-w>j";
        key = "<C-j>";
        mode = "n";
      }
      {
        action = "<C-w>k";
        key = "<C-k>";
        mode = "n";
      }
      {
        action = "<C-w>l";
        key = "<C-l>";
        mode = "n";
      }
    ];

    plugins = {
      # languages
      nix.enable = true;
      markdown-preview.enable = true;
      rust-tools.enable = true;

      treesitter = {
        enable = true;
        indent = true;
      };

      chadtree = {
        enable = true;
        keymap = {
          windowManagement.quit = [ "q" "t" ];
          fileOperations.trash = [ "D" ];
        };
      };

      nvim-colorizer = {
        enable = true;
        userDefaultOptions.names = false;
      };
      fidget.enable = true;
      lightline.enable = true;
      indent-blankline = {
        enable = true;
      };
      gitgutter.enable = true;
      telescope.enable = true;
      nvim-autopairs.enable = true;
      trouble.enable = true;
      nvim-lightbulb.enable = true;
      comment.enable = true;
      barbecue.enable = true;
      lastplace.enable = true;
      illuminate.enable = true;
      which-key.enable = true;
      sleuth.enable = true;
      todo-comments.enable = true;
      copilot-vim.enable = true;
      treesitter-context = {
        enable = true;
        settings.separator = "—";
      };
      toggleterm.enable = true;
      helm.enable = true;

      # stuff that isnt in nixvim needs to be installed with lazy
      # lazy = {
      #   enable = true;
      #   plugins = {
      #     "kdheepak/lazygit.nvim" = {
      #       enable = true;
      #       cmd = "LazyGit";
      #       keys = [
      #         ''{ "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }''
      #       ];
      #     };
      #   };
      # };

      cmp-treesitter.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-nvim-lsp-signature-help.enable = true;
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          window.completion.border = "rounded";
          window.documentation.border = "rounded";
          sources = [
            {
              groupIndex = 1;
              name = "nvim_lsp";
            }
            {
              groupIndex = 2;
              name = "path";
            }
          ];
          preselect = "None";
          snippet.expand = "luasnip";
          mapping = {
            __raw = /* lua */ ''
              cmp.mapping.preset.insert {
                -- Select the [n]ext item
                ['<C-n>'] = cmp.mapping.select_next_item(),
                -- Select the [p]revious item
                ['<C-p>'] = cmp.mapping.select_prev_item(),
      
                -- Accept ([y]es) the completion.
                --  This will auto-import if your LSP supports it.
                --  This will expand snippets if the LSP sent a snippet.
                ['<C-y>'] = cmp.mapping.confirm { select = true },
      
                -- Manually trigger a completion from nvim-cmp.
                --  Generally you don't need this, because nvim-cmp will display
                --  completions whenever it has completion options available.
                ['<C-Space>'] = cmp.mapping.complete {},
      
                -- Think of <c-l> as moving to the right of your snippet expansion.
                --  So if you have a snippet that's like:
                --  function $name($args)
                --    $body
                --  end
                --
                -- <c-l> will move you to the right of each of the expansion locations.
                -- <c-h> is similar, except moving you backwards.
                ['<C-l>'] = cmp.mapping(function()
                  if luasnip.expand_or_locally_jumpable() then
                    luasnip.expand_or_jump()
                  end
                end, { 'i', 's' }),
                ['<C-h>'] = cmp.mapping(function()
                  if luasnip.locally_jumpable(-1) then
                    luasnip.jump(-1)
                  end
                end, { 'i', 's' }),
              }
            '';
          };
        };
      };

      lsp-format.enable = true;

      none-ls = {
        enable = true;
        enableLspFormat = true;
        sources = {
          code_actions = {
            statix.enable = true;
            refactoring.enable = true;
          };
          diagnostics = {
            deadnix.enable = true;
            gitlint.enable = true;
            selene.enable = true;
          };
          formatting = {
            markdownlint.enable = true;
            sqlfluff.enable = true;
            shfmt = {
              enable = true;
              withArgs = ''
                { extra_args = {
                  '-i', '4', '-ci'
                } }
              '';
            };
            stylua.enable = true;
            terraform_fmt.enable = true;
          };
        };
      };

      lsp = {
        enable = true;
        keymaps = {
          diagnostic = {
            # vim.diagnostic.#
            "<leader>e" = "open_float";
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
          };
          lspBuf = {
            # vim.lsp.buf.#
            "gd" = "definition";
            "gt" = "type_definition";
            "gr" = "references";
            "gi" = "implementation";
            "K" = "hover";
            "<leader>ca" = "code_action";
            "<leader>rn" = "rename";
          };
        };
        servers = {
          nil_ls = {
            enable = false;
            settings.formatting.command = [ "alejandra" ];
          };
          lua-ls.enable = true;
          bashls.enable = true;
          tailwindcss.enable = true;
          tsserver.enable = true;
          hls.enable = true;
          jsonls.enable = true;
          clangd.enable = true;
          #          terraformls.enable = true;
          helm-ls = {
            enable = true;
            # onAttach.function = ''
            #   if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "helm" then
            #     vim.diagnostic.disable() 
            #   end
            # '';
            extraOptions = {
              settings = {
                "helm-ls" = {
                  yamlls = {
                    path = "yaml-language-server";
                  };
                };
              };
            };
          };
          gopls.enable = true;
          kotlin-language-server.enable = true;
          ruff-lsp = {
            enable = true;
          };
          yamlls = {
            enable = true;
            # extraOptions = {
            #   settings = {
            #     yaml = {
            #       schemas = {
            #         kubernetes = "*.yaml";
            #         "http://json.schemastore.org/github-workflow" = ".github/workflows/*";
            #         "http://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
            #         "http://json.schemastore.org/ansible-stable-2.9" = "roles/tasks/*.{yml,yaml}";
            #         "http://json.schemastore.org/prettierrc" = ".prettierrc.{yml,yaml}";
            #         "http://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
            #         "http://json.schemastore.org/ansible-playbook" = "*play*.{yml,yaml}";
            #         "http://json.schemastore.org/chart" = "Chart.{yml,yaml}";
            #         "https://json.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
            #         "https://json.schemastore.org/gitlab-ci" = "*gitlab-ci*.{yml,yaml}";
            #         "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json" = "*api*.{yml,yaml}";
            #         "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = "*docker-compose*.{yml,yaml}";
            #         "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" = "*flow*.{yml,yaml}";
            #       };
            #     };
            #   };
            # };
          };
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      smartcolumn-nvim
      lazygit-nvim
    ];

    extraConfigLua = /* lua */ ''
      vim.api.nvim_create_autocmd('TextYankPost', {
        desc = 'Highlight when yanking (copying) text',
        group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
        callback = function()
          vim.highlight.on_yank()
        end,
      })

      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )

      require("smartcolumn").setup()
    '';
  };
}
