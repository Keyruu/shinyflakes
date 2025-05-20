return {
  "saghen/blink.cmp",
  dependencies = {
    "milanglacier/minuet-ai.nvim",
  },
  config = function()
    require("blink-cmp").setup({
      keymap = {
        -- Manually invoke minuet completion.
        ["<C-Tab>"] = require("minuet").make_blink_map(),
      },
      sources = {
        -- Enable minuet for autocomplete
        default = { "lsp", "path", "buffer", "snippets", "minuet" },
        -- For manual completion only, remove 'minuet' from default
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            -- Should match minuet.config.request_timeout * 1000,
            -- since minuet.config.request_timeout is in seconds
            timeout_ms = 3000,
            score_offset = 50, -- Gives minuet higher priority among suggestions
          },
        },
      },
      -- Recommended to avoid unnecessary request
      completion = {
        trigger = { prefetch_on_insert = false },
      },
    })
  end,
}
