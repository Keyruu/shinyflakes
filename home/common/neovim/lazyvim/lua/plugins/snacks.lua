return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>fF", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    { "<leader>ff", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
    { "<leader>sG", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
    { "<leader>sg", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
    { "<leader>fG", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
    { "<leader>fg", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
    {
      "<leader>tf",
      function()
        require("snacks.terminal").toggle("fish")
      end,
      desc = "[T]erminal [f]loating",
    },
    {
      "<leader>tk",
      function()
        require("snacks.terminal").toggle("k9s")
      end,
      desc = "[T]erminal [k]9s",
    },
    {
      "<leader>tt",
      function()
        Snacks.terminal(nil, {
          win = {
            height = 0.25,
            wo = {
              winbar = "🐟: %{b:term_title}",
            },
          },
        })
      end,
      desc = "Open [T]erminal",
    },
    {
      "<leader>tv",
      function()
        Snacks.terminal.open(nil, { split = "vertical" })
      end,
      desc = "Open [T]erminal [v]ertically",
    },
    {
      "<leader>tao",
      function()
        require("snacks.terminal").toggle("opencode")
      end,
      desc = "[T]erminal [A]I [O]penCode",
    },
    {
      "<leader>tas",
      function()
        require("snacks.terminal").toggle("opencode-sst", {
          win = {
            position = "right",
            width = 0.3,
          },
        })
      end,
      desc = "[T]erminal [A]I OpenCode by [S]ST",
    },
    {
      "<leader>tac",
      function()
        require("snacks.terminal").toggle("claude")
      end,
      desc = "[T]erminal [A]I [C]laude Code",
    },
  },
  opts = {
    ---@type table<string, snacks.win.Config>
    styles = {
      zen = {
        backdrop = { transparent = false, bg = "#0c0e0f" },
      },
    },
  },
  config = function(_, opts)
    -- Call the original snacks setup
    require("snacks").setup(opts)

    vim.defer_fn(function()
      local file_watcher = require("config.file-watcher")
      file_watcher.setup_terminal_integration()
    end, 100)
  end,
}
