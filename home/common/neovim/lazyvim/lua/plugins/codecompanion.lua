return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "ravitemer/mcphub.nvim",
    "j-hui/fidget.nvim",
    "MeanderingProgrammer/render-markdown.nvim",
  },
  opts = {
    display = {
      diff = {
        enabled = true,
        provider = "mini_diff", -- default|mini_diff
      },
    },
    strategies = {
      chat = {
        adapter = "claude_code",
      },
      inline = {
        adapter = "gemini",
        keymaps = {
          reject_change = {
            modes = { n = "gR" },
            description = "Reject the suggested change",
          },
        },
      },
    },
    adapters = {
      acp = {
        claude_code = function()
          return require("codecompanion.adapters").extend("claude_code", {
            env = {
              ANTHROPIC_API_KEY = "ANTHROPIC_API_KEY",
            },
          })
        end,
      },
      gemini = function()
        return require("codecompanion.adapters").extend("gemini", {
          schema = {
            model = {
              default = "gemini-2.5-pro-preview-05-06",
            },
          },
          env = {
            api_key = "GEMINI_API_KEY",
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
    },
  },
  init = function()
    require("plugins.codecompanion.fidget-spinner"):init()
  end,
}
