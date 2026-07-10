require("quicker").setup({
  keys = {
    {
      "Q",
      "<Cmd>:q<CR>",
      desc = "Close quickfix"
    },
    {
      ">",
      function()
        require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
      end,
      desc = "Expand quickfix context",
    },
    {
      "<",
      function()
        require("quicker").collapse()
      end,
      desc = "Collapse quickfix context",
    },
  },
})
require("conform").setup({})
require("yazi").setup({})
require("flash").setup({})
require("todo-comments").setup({})
require("grug-far").setup({})
require("outline").setup({ outline_items = { show_symbol_details = true } })

require("mini.tabline").setup({})
require("mini.ai").setup({})
require("mini.surround").setup({})
require("mini.snippets").setup({})

require("treesitter-context").setup({
  separator = "—",
  max_lines = 5,
})
require("render-markdown").setup({})
