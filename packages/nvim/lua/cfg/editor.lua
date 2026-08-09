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
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    nix = { "nixfmt" },
    markdown = { "prettier" },
    yaml = { "prettier" },
    json = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
  },
  format_on_save = { lsp_format = "fallback" },
})
require("lint").linters_by_ft = {
  markdown = { "markdownlint-cli2" },
}
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
  callback = function()
    require("lint").try_lint(nil, { ignore_errors = true })
  end,
})

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
