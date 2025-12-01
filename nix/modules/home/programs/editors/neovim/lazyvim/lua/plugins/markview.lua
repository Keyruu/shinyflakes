return {
  "OXY2DEV/markview.nvim",
  enabled = false,
  lazy = false, -- Recommended
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    preview = {
      filetypes = { "markdown", "codecompanion" },
      ignore_buftypes = {},
    },
  },
}
