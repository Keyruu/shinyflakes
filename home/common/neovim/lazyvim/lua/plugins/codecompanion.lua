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
        -- Enable tools for chat strategy
        tools = {
          -- Use full_stack_dev group for comprehensive coding support
          groups = { "full_stack_dev" },
          -- Or specify individual tools:
          -- enabled = { "insert_edit_into_file", "read_file", "file_search", "grep_search" },
        },
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
    -- Configure tools behavior
    tools = {
      -- Configure insert_edit_into_file tool
      insert_edit_into_file = {
        -- Patching algorithm for edits
        patching_algorithm = "heuristic", -- default|mini_diff|heuristic
        requires_approval = {
          buffer = false, -- Direct buffer edits don't need approval
          file = true, -- File edits require approval for safety
        },
        user_confirmation = true, -- Always confirm before applying changes
      },
      -- Configure other tools as needed
      cmd_runner = {
        user_confirmation = true, -- Require confirmation for system commands
      },
      create_file = {
        user_confirmation = true, -- Confirm before creating files
      },
      -- Enable YOLO mode for testing (disable confirmations)
      -- WARNING: Only use this if you trust the LLM completely
      -- yolo_mode = false,
    },
    adapters = {
      acp = {
        claude_code = function()
          return require("codecompanion.adapters").extend("claude_code", {
            env = {
              ANTHROPIC_API_KEY = "ANTHROPIC_API_KEY",
            },
            -- Claude Code supports advanced tool usage
            features = {
              tools = true,
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
          -- Gemini also supports tools
          features = {
            tools = true,
          },
        })
      end,
      anthropic = function()
        return require("codecompanion.adapters").extend("anthropic", {
          env = {
            api_key = "ANTHROPIC_API_KEY",
          },
          features = {
            tools = true,
          },
        })
      end,
    },
  },
  -- Add keymaps for quick tool usage
  keys = {
    -- Example: Ask AI to edit current buffer
    {
      "<leader>ce",
      function()
        vim.cmd('CodeCompanion "Use @{insert_edit_into_file} to improve the code in #buffer"')
      end,
      desc = "Edit buffer with AI",
    },
    -- Example: Refactor selected code
    {
      "<leader>cr",
      function()
        vim.cmd('CodeCompanion "Use @{insert_edit_into_file} to refactor the selected code in #buffer"')
      end,
      mode = "v",
      desc = "Refactor selection with AI",
    },
  },
  init = function()
    require("plugins.codecompanion.fidget-spinner"):init()
  end,
}
