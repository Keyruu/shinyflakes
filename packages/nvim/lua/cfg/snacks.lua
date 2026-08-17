require("snacks").setup({
	bigfile = { enabled = true },
	dashboard = { enabled = false },
	indent = { enabled = true, animate = { enabled = false } },
	input = { enabled = true },
	lazygit = { enabled = true, config = { os = { editPreset = "nvim-remote" } } },
	picker = { enabled = false },
	notifier = { enabled = true },
	quickfile = { enabled = true },
	terminal = { enabled = true, win = { stack = true } },
	toggle = { enabled = true },
})

local map = require("cfg.util").map

map("n", "_", function()
	Snacks.explorer({ hidden = true, auto_close = true, layout = { preset = "default", preview = true } })
end, "Explorer")
map("n", "<leader>e", function()
	Snacks.explorer({ hidden = true, auto_close = true })
end, "Explorer")
map("n", "<leader>gg", function()
	Snacks.lazygit()
end, "Lazygit")
map("n", "<leader>tt", function()
	Snacks.terminal()
end, "Toggle terminal")
map("n", "<leader>tp", function()
	Snacks.terminal("pi", { win = { position = "right", width = 0.4 } })
end, "Pi agent terminal")
