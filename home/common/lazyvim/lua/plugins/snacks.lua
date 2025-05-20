return {
  "snacks.nvim",
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
  },
}
