require("snacks").setup({
	bigfile = { enabled = true },
	dashboard = { enabled = false },
	indent = { enabled = true, animate = { enabled = false } },
	input = { enabled = true },
	lazygit = { enabled = true, config = { os = { editPreset = "nvim-remote" } } },
	picker = { enabled = true },
	notifier = { enabled = true },
	quickfile = { enabled = true },
	terminal = { enabled = true, win = { stack = true } },
	toggle = { enabled = true },
})

local map = require("cfg.util").map

map("n", "<leader><space>", function()
	Snacks.picker.smart({ hidden = true })
end, "Smart find files")
map("n", "<leader>ff", function()
	Snacks.picker.files({ hidden = true })
end, "Find files")
map("n", "<leader>fg", function()
	Snacks.picker.grep({ hidden = true })
end, "Grep")
map("n", "<leader>fb", function()
	Snacks.picker.buffers({ hidden = true })
end, "Buffers")
map("n", "<leader>,", function()
	Snacks.picker.buffers()
end, "Buffers")
map("n", "<leader>/", function()
	Snacks.picker.grep()
end, "Grep")
map("n", "<leader>:", function()
	Snacks.picker.command_history()
end, "Command history")
map("n", "<leader>fc", function()
	Snacks.picker.commands()
end, "Command palette")
map("n", "<leader>fk", function()
	Snacks.picker.keymaps()
end, "Keymaps")
map("n", "<leader>n", function()
	Snacks.picker.notifications()
end, "Notification history")
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
