vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		vim.cmd("wincmd =")
	end,
})

local function update_terminal_highlights()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) then
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].buftype == "terminal" then
				local focused = win == vim.api.nvim_get_current_win()
				vim.api.nvim_set_option_value("winhighlight", focused and "" or "Normal:NormalNC", { win = win })
			end
		end
	end
end
vim.api.nvim_create_autocmd(
	{ "WinEnter", "WinLeave", "TermOpen", "BufWinEnter", "WinClosed", "TabEnter", "FocusGained", "BufEnter" },
	{
		callback = function()
			vim.schedule(update_terminal_highlights)
		end,
	}
)
