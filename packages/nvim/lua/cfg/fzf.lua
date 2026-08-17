require("fzf-lua").setup({ "fzf-native" })

local map = require("cfg.util").map
local fzf = function(name)
	return function(opts)
		opts = vim.tbl_extend("force", { hidden = true }, opts or {})
		require("fzf-lua")[name](opts)
	end
end

map("n", "<leader><space>", fzf("live_grep"), "Live grep")
map("n", "<leader>ff", fzf("files"), "Find files")
map("n", "<leader>fg", fzf("live_grep"), "Live grep")
map("n", "<leader>fb", fzf("buffers"), "Buffers")
map("n", "<leader>,", fzf("buffers"), "Buffers")
map("n", "<leader>/", fzf("live_grep"), "Live grep")
map("n", "<leader>:", fzf("command_history"), "Command history")
map("n", "<leader>fc", fzf("commands"), "Command palette")
map("n", "<leader>fk", fzf("keymaps"), "Keymaps")
