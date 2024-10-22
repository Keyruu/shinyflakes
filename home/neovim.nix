{
  pkgs,
  username,
  ...
}: {
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
      conceallevel = 0;
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
        key = "<leader>ef";
        action = ":Oil<CR>";
        mode = "n";
        options = {
          desc = "Oil - File Browser";
        };
      }
      {
        key = "-";
        action = ":Oil<CR>";
        mode = "n";
        options = {
          desc = "Oil - File Browser";
        };
      }
      {
        key = "<leader>t";
        action = "<cmd>ToggleTerm direction=horizontal<cr>";
        mode = "n";
        options = {
          desc = "ToggleTerm";
        };
      }
      {
        key = "<leader>lg";
        action = "<cmd>LazyGit<cr>";
        mode = "n";
        options = {
          desc = "LazyGit";
        };
      }
      {
        key = ";;";
        action = "<C-\\><C-n>";
        mode = "t";
        options = {
          desc = "Exit terminal mode";
        };
      }
      {
        key = "<leader>q";
        action = ":q<CR>";
        mode = "n";
        options = {
          desc = "Quit";
        };
      }
      {
        key = "<leader>Q";
        action = ":qa<CR>";
        mode = "n";
        options = {
          desc = "Quit all";
        };
      }
      {
        key = "<leader>w";
        action = ":w<CR>";
        mode = "n";
        options = {
          desc = "Write";
        };
      }
      {
        # this is here because it needs insert mode
        key = "<C-h>";
        action.__raw = "vim.lsp.buf.signature_help";
        mode = "i";
      }
      {
        # don't override buffer when pasting
        key = "p";
        action = ''"_dP'';
        mode = "x";
        options = {
          desc = "Paste - no buffer override";
        };
      }
      {
        # copy to system clipboard
        key = "<leader>y";
        action = ''"+y'';
        mode = ["n" "x" "v"];
        options = {
          desc = "Copy to system clipboard";
        };
      }
      {
        # delete to system clipboard
        key = "<leader>d";
        action = ''"+d'';
        mode = ["n" "x" "v"];
        options = {
          desc = "Delete to system clipboard";
        };
      }
      {
        # delete to system clipboard
        key = "<leader>p";
        action = ''"+p'';
        mode = ["n" "x" "v"];
        options = {
          desc = "Paste from system clipboard";
        };
      }
      # {
      #   # no macro menu
      #   action = "<nop>";
      #   key = "q";
      #   mode = "n";
      # }
      # move between windows with ctrl hjkl
      {
        key = "<C-h>";
        action = "<C-w>h";
        mode = "n";
        options = {
          desc = "Focus window to west";
        };
      }
      {
        key = "<C-j>";
        action = "<C-w>j";
        mode = "n";
        options = {
          desc = "Focus window to south";
        };
      }
      {
        key = "<C-k>";
        action = "<C-w>k";
        mode = "n";
        options = {
          desc = "Focus window to north";
        };
      }
      {
        key = "<C-l>";
        action = "<C-w>l";
        mode = "n";
        options = {
          desc = "Focus window to east";
        };
      }
      {
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<cr>";
        mode = "n";
        options = {
          desc = "Telescope find files";
        };
      }
      {
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
        mode = "n";
        options = {
          desc = "Telescope live grep";
        };
      }
      {
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<cr>";
        mode = "n";
        options = {
          desc = "Telescope buffers";
        };
      }
      {
        key = "<leader>fh";
        action = "<cmd>Telescope help_tags<cr>";
        mode = "n";
        options = {
          desc = "Telescope help tags";
        };
      }
      {
        key = "<leader>?";
        action = ''<cmd>lua require("which-key").show({ global = false })<cr>'';
        mode = "n";
        options = {
          desc = "Buffer Local Keymaps (which-key)";
        };
      }
      {
        key = "<leader>z";
        action = ''<cmd>lua require("yazi").yazi()<cr>'';
        mode = "n";
        options = {
          desc = "Yazi in cwd";
        };
      }
      {
        key = "<leader>s";
        action = ''<cmd>noh<cr>'';
        mode = "n";
        options = {
          desc = "Turn off highlight until next search";
        };
      }
      {
        key = "<leader>K";
        action = ''<cmd>lua require("kubectl").toggle()<cr>'';
        mode = "n";
        options = {
          desc = "Toggle kubectl.nvim";
        };
      }
    ];

    plugins = {
      # languages
      nix.enable = true;
      markdown-preview.enable = true;
      rust-tools.enable = true;

      treesitter = {
        enable = true;
        settings = {
          indent.enable = true;
          highlight.enable = true;
        };
      };

      obsidian = {
        enable = false;
        settings = {
          workspaces = [
            {
              path = "~/git/private/obsidian/";
              name = "obsidian";
            }
            {
              path = "~/git/private/oblivion/content/";
              name = "oblivion";
            }
          ];
        };
      };

      oil = {
        enable = true;
      };

      chadtree = {
        enable = false;
        keymap = {
          windowManagement.quit = ["q" "t"];
          fileOperations.trash = ["D"];
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
      # copilot-vim.enable = true;
      treesitter-context = {
        enable = true;
        settings.separator = "—";
      };
      toggleterm.enable = true;
      helm.enable = true;
      arrow = {
        enable = true;
        settings = {
          show_icons = true;
          leader_key = ";";
          buffer_leader_key = "m";
        };
      };
      noice.enable = true;
      lazygit.enable = true;
      mini.enable = true;
      fugitive.enable = true;
      autoclose.enable = true;
      dap.enable = true;
      leap.enable = true;
      floaterm.enable = true;

      # stuff that isnt in nixvim needs to be installed with lazy
      # lazy = {
      #   enable = true;
      #   plugins = [
      #     {
      #       name = "supermaven-inc/supermaven-nvim";
      #     }
      #   ];
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
            __raw =
              /*
              lua
              */
              ''
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
              settings = {
                extra_args = [
                  "-i"
                  "4"
                  "-ci"
                ];
              };
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
          nixd.enable = false;
          nil-ls = {
            enable = true;
            settings = {
              formatting.command = ["alejandra"];
              flake.autoEvalInputs = true;
            };
          };
          lua-ls.enable = true;
          bashls.enable = true;
          tailwindcss.enable = true;
          tsserver.enable = true;
          hls.enable = true;
          jsonls.enable = true;
          clangd.enable = true;
          terraformls.enable = true;
          helm-ls = {
            enable = true;
          };
          gopls.enable = true;
          kotlin-language-server.enable = true;
          intelephense.enable = true;
          ruff-lsp = {
            enable = true;
          };
          yamlls = {
            enable = true;
            # onAttach.function = /* lua */ ''
            #   if vim.bo[bufnr].filetype == "helm" then
            #     vim.schedule(function()
            #       vim.cmd("LspStop ++force yamlls")
            #     end)
            #   end
            # '';
            extraOptions = {
              settings = {
                yaml = {
                  schemas = {
                    kubernetes = "/*.yaml";
                    "http://json.schemastore.org/github-workflow" = ".github/workflows/*";
                    "http://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
                    "http://json.schemastore.org/ansible-stable-2.9" = "roles/tasks/*.{yml,yaml}";
                    "http://json.schemastore.org/prettierrc" = ".prettierrc.{yml,yaml}";
                    "http://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
                    "http://json.schemastore.org/ansible-playbook" = "*play*.{yml,yaml}";
                    "http://json.schemastore.org/chart" = "Chart.{yml,yaml}";
                    "https://json.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
                    "https://json.schemastore.org/gitlab-ci" = "*gitlab-ci*.{yml,yaml}";
                    "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json" = "*api*.{yml,yaml}";
                    "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = "*docker-compose*.{yml,yaml}";
                    "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" = "*flow*.{yml,yaml}";
                  };
                };
              };
            };
          };
        };
      };
    };

    extraPlugins = let
      kubectl-nvim = pkgs.vimUtils.buildVimPlugin {
        name = "kubectl-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "Ramilito";
          repo = "kubectl.nvim";
          rev = "d216502e7926a4341c96d847f223df6957f652f2";
          hash = "sha256-xLcUcnYyly1qrHVCIk4FbRV70IaYGV8c5f9TRMouGwY=";
        };
      };
    in
      with pkgs.vimPlugins; [
        smartcolumn-nvim
        lazygit-nvim
        yazi-nvim
        kubectl-nvim
        #xcodebuild-nvim
        #supermaven-nvim
      ];

    extraConfigLua =
      /*
      lua
      */
      ''
        vim.api.nvim_create_autocmd('TextYankPost', {
          desc = 'Highlight when yanking (copying) text',
          group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
          callback = function()
            vim.highlight.on_yank()
          end,
        })

        vim.api.nvim_create_autocmd({'BufNewFile', 'BufRead'} , {
          pattern = '*/templates/*.yaml,*/templates/**/*.yaml,values.yaml',
          callback = function()
            vim.opt_local.filetype = 'helm'
          end
        })

        local cmp_autopairs = require('nvim-autopairs.completion.cmp')
        local cmp = require('cmp')
        cmp.event:on(
          'confirm_done',
          cmp_autopairs.on_confirm_done()
        )

        require("smartcolumn").setup()
        -- require("supermaven-nvim").setup({
        --   keymaps = {
        --     accept_suggestion = "<Tab>",
        --     clear_suggestion = "<C-]>",
        --     accept_word = "<C-j>",
        --   }
        -- })
        require("yazi").setup()
        require("kubectl").setup()
      '';
  };
}
