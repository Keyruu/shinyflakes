{
  pkgs,
  perSystem,
  lib,
  config,
  ...
}:
{
  programs.nvf.settings.vim = {
    utility = {
      direnv.enable = true;
      preview.glow.enable = true;
      motion.flash-nvim.enable = true;
      snacks-nvim = {
        enable = true;
        setupOpts = {
          bigfile.enabled = true;
          dashboard.enabled = false;
          indent = {
            enabled = true;
            animate.enabled = false;
          };
          input.enabled = true;
          lazygit = {
            enabled = true;
            config = {
              os = {
                editPreset = "nvim-remote";
              };
            };
          };
          picker.enabled = true;
          notifier.enabled = true;
          quickfile.enabled = true;
          terminal = {
            enabled = true;
            win = {
              stack = true;
            };
          };
          toggle.enabled = true;
        };
      };
      yanky-nvim.enable = false;
      yazi-nvim = {
        enable = true;
        setupOpts = {
          # Use a separate yazi config with image/PDF previews disabled
          # to prevent escape sequence leakage in Neovim's terminal
          config_home = "${config.xdg.configHome}/yazi-nvim";
        };
      };
    };
    notes = {
      todo-comments.enable = true;
    };

    assistant = {
      codecompanion-nvim = {
        enable = true;
        setupOpts = {
          adapters =
            lib.generators.mkLuaInline # lua
              ''
                {
                  opencode_go = function()
                    return require("codecompanion.adapters").extend("openai_compatible", {
                      env = {
                        url = "https://opencode.ai/zen/go/v1",
                        api_key = "OPENCODE_API_KEY",
                        chat_url = "/chat/completions",
                      },
                      schema = {
                        model = {
                          default = "glm-5",
                        },
                      },
                    })
                  end,
                  anthropic = function()
                    return require("codecompanion.adapters").extend("anthropic", {
                      env = {
                        api_key = "ANTHROPIC_API_KEY",
                      },
                    })
                  end,
                }
              '';
          strategies = {
            chat = {
              adapter = "opencode";
            };
            inline = {
              adapter = "opencode_go";
              keymaps = {
                accept_change = {
                  modes.n = "ga";
                  description = "Accept the suggested change";
                };
                reject_change = {
                  modes.n = "gr";
                  opts = {
                    nowait = true;
                  };
                  description = "Reject the suggested change";
                };
              };
            };
          };
        };
      };
    };

    lazy.plugins = {
      "opencode.nvim" = {
        package = pkgs.vimPlugins.opencode-nvim;
        after = # lua
          ''
            ---@type opencode.Opts
            vim.g.opencode_opts = {
              -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition".
            }

            -- Required for `opts.events.reload`.
            vim.o.autoread = true

            -- Recommended/example keymaps.
            vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode" })
            vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end,                          { desc = "Execute opencode action…" })
            vim.keymap.set({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end,                          { desc = "Toggle opencode" })

            vim.keymap.set({ "n", "x" }, "go",  function() return require("opencode").operator("@this ") end,        { expr = true, desc = "Add range to opencode" })
            vim.keymap.set("n",          "goo", function() return require("opencode").operator("@this ") .. "_" end, { expr = true, desc = "Add line to opencode" })

            vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,   { desc = "opencode half page up" })
            vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "opencode half page down" })
          '';
      };
    };

    extraPlugins = with pkgs.vimPlugins; {
      kanagawa-nvim = {
        package = kanagawa-nvim;
        setup = # lua
          ''
            require('kanagawa').setup({
              transparent = false,
              terminalColors = false,
              colors = {
                palette = {
                  sumiInk0 = "#0c0e0f",
                  sumiInk1 = "#0e1011",
                  sumiInk2 = "#101213",
                  sumiInk3 = "#121415",
                  sumiInk4 = "#141617",
                  sumiInk5 = "#161819",
                  oldWhite = "#dae1e6",
                },
                theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
              },
              overrides = function(colors)
                local palette = colors.palette
                return {
                  -- Dim unfocused windows
                  NormalNC = { bg = palette.sumiInk0 },
                }
              end,
              theme = "wave",
              background = {
                dark = "wave",
                light = "lotus",
              },
            })
            vim.cmd.colorscheme('kanagawa')
          '';
      };
      codediff-nvim = {
        package = codediff-nvim;
        setup = # lua
          ''
            require('codediff').setup({})
          '';
      };
      grug-far-nvim = {
        package = grug-far-nvim;
        setup = # lua
          ''
            require('grug-far').setup({})
          '';
      };
      jira-nvim = {
        package = perSystem.self.jira-nvim;
        setup = # lua
          ''
            require('jira').setup({})
          '';
      };
      kubectl-nvim = {
        package = perSystem.kubectl-nvim.default;
        setup = # lua
          ''
            require('kubectl').setup({})
          '';
      };
    };

    startPlugins = with pkgs.vimPlugins; [
      plenary-nvim
      nvim-numbertoggle
    ];
  };
}
