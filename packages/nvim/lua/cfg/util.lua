local M = {}

-- Shortcut for vim.keymap.set with silent + desc defaults baked in.
function M.map(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

return M
