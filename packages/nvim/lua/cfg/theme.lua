require("kanagawa").setup({
	transparent = true,
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
		return { NormalNC = { bg = colors.palette.sumiInk0 } }
	end,
	theme = "wave",
	background = { dark = "wave", light = "lotus" },
})
vim.cmd.colorscheme("kanagawa")
