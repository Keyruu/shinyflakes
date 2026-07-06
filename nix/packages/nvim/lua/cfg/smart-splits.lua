require("smart-splits").setup({
	-- 'stop' only kicks in when no multiplexer pane exists in that
	-- direction; tmux handoff still works otherwise.
	at_edge = "stop",
	cursor_follows_swapped_bufs = true,
	multiplexer_integration = "tmux",
})

local grp = vim.api.nvim_create_augroup("SmartSplitsTmuxFlag", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
	group = grp,
	callback = function()
		vim.fn.system("tmux set -p @pane-is-vim 1")
	end,
})
vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
	group = grp,
	callback = function()
		vim.fn.system("tmux set -p @pane-is-vim 0")
	end,
})

local map = require("cfg.util").map

for _, m in ipairs({ "n", "t", "i" }) do
	map(m, "<C-h>", "<Cmd>SmartCursorMoveLeft<CR>", "Window/pane left")
	map(m, "<C-j>", "<Cmd>SmartCursorMoveDown<CR>", "Window/pane down")
	map(m, "<C-k>", "<Cmd>SmartCursorMoveUp<CR>", "Window/pane up")
	map(m, "<C-l>", "<Cmd>SmartCursorMoveRight<CR>", "Window/pane right")
end
