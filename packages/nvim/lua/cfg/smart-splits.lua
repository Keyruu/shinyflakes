require("smart-splits").setup({
	move = { at_edge = "stop" },
	mux = {
		backend = { "smart-splits-backend-tmux", "smart-splits-backend-zellij-lua" },
	},
})

local map = require("cfg.util").map

for _, m in ipairs({ "n", "t", "i" }) do
	map(m, "<C-h>", "<Cmd>SmartCursorMoveLeft<CR>", "Window/pane left")
	map(m, "<C-j>", "<Cmd>SmartCursorMoveDown<CR>", "Window/pane down")
	map(m, "<C-k>", "<Cmd>SmartCursorMoveUp<CR>", "Window/pane up")
	map(m, "<C-l>", "<Cmd>SmartCursorMoveRight<CR>", "Window/pane right")
end
