return {
  "rebelot/kanagawa.nvim",
  priority = 1000, -- Make sure to load this before all the other start plugins.
  config = function()
    require("kanagawa").setup({
      transparent = false, -- do not set background color
      terminalColors = false, -- define vim.g.terminal_color_{0,17}
      colors = { -- add/modify theme and palette colors
        palette = {
          sumiInk0 = "#0c0e0f",
          sumiInk1 = "#0e1011",
          sumiInk2 = "#101213",
          sumiInk3 = "#121415",
          sumiInk4 = "#141617",
          sumiInk5 = "#161819",

          -- boatYellow1 = '#dae1e6',
          -- boatYellow2 = '#dae1e6',
          -- carpYellow = '#dae1e6',
          -- roninYellow = '#dae1e6',
          -- fujiWhite = '#dae1e6',
          oldWhite = "#dae1e6",
        },
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      },
      overrides = function(colors) -- add/modify highlights
        return {}
      end,
      theme = "wave", -- Load "wave" theme
      background = { -- map the value of 'background' option to a theme
        dark = "wave", -- try "dragon" !
        light = "lotus",
      },
    })

    vim.cmd.colorscheme("kanagawa")
  end,
}
