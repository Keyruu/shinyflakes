vim.opt.rtp:prepend(arg[1] .. "/packages/pi-guardian-nvim")
local Guardian = require("pi-guardian")
assert(Guardian.guided_review_version == 2)
local Buffers = require("pi-guardian.buffers")
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local sequence = 0
local function open()
	sequence = sequence + 1
	local path = dir .. "/file-" .. sequence
	local response = dir .. "/response-" .. sequence
	Buffers.write_file(path, "proposed\n")
	Guardian.review({ path = path, original = "before\n", proposed = "proposed\n", response_file = response })
	return path, response, vim.fn.bufnr(path)
end
local function key(buf, name)
	vim.api.nvim_buf_call(buf, function()
		local mapping = vim.fn.maparg(name, "n", false, true)
		assert(type(mapping.callback) == "function", name .. " mapping missing")
		mapping.callback()
	end)
end
local ok, err = pcall(function()
	local path, response, buf = open()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "unsaved human edit" })
	key(buf, "gx")
	vim.wait(250, function()
		return false
	end)
	assert(vim.deep_equal(vim.json.decode(Buffers.read_file(response)), { decision = "block" }))
	assert(Buffers.read_file(path) == "proposed\n")
	assert(vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified)
	assert(Buffers.read_buf_content(buf) == "unsaved human edit\n")
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("write")
	end)
	assert(Buffers.read_file(path) == "unsaved human edit\n", "ordinary save must work after stop")

	path, response, buf = open()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "saved human edit" })
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("write")
	end)
	assert(vim.fn.filereadable(response) == 0, "saving is not acceptance")
	key(buf, "gx")
	assert(Buffers.read_file(path) == "saved human edit\n")

	path, response, buf = open()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "accepted human edit" })
	key(buf, "ga")
	assert(vim.deep_equal(vim.json.decode(Buffers.read_file(response)), { decision = "allow" }))
	assert(Buffers.read_file(path) == "accepted human edit\n")

	path, response, buf = open()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "unsaved competing edit" })
	Buffers.write_file(path, "concurrent save\n")
	key(buf, "ga")
	assert(vim.fn.filereadable(response) == 0, "stale acceptance must be refused")
	assert(Buffers.read_file(path) == "concurrent save\n")
	Guardian._active_reject()
	assert(Buffers.read_file(path) == "concurrent save\n")
	assert(Buffers.read_buf_content(buf) == "unsaved competing edit\n")

	path, response, buf = open()
	vim.cmd("tabclose")
	vim.wait(50, function()
		return vim.fn.filereadable(response) == 1
	end)
	assert(vim.json.decode(Buffers.read_file(response)).decision == "block")
	assert(Buffers.read_file(path) == "proposed\n")

	path = dir .. "/clean-preexisting"
	Buffers.write_file(path, "before\n")
	vim.cmd("edit " .. vim.fn.fnameescape(path))
	buf = vim.api.nvim_get_current_buf()
	vim.o.autoread = false
	Buffers.write_file(path, "proposed\n")
	response = dir .. "/clean-preexisting-response"
	Guardian.review({ path = path, original = "before\n", proposed = "proposed\n", response_file = response })
	assert(Buffers.read_buf_content(buf) == "proposed\n", "clean buffers must reload tool edits")
	key(buf, "ga")
	assert(Buffers.read_file(path) == "proposed\n")

	Buffers.write_file(path, "newer external content\n")
	response = dir .. "/stale-response"
	Guardian.review({ path = path, original = "before\n", proposed = "proposed\n", response_file = response })
	assert(vim.json.decode(Buffers.read_file(response)).decision == "block")
	assert(Buffers.read_file(path) == "newer external content\n")

	path = dir .. "/preexisting"
	Buffers.write_file(path, "proposed\n")
	vim.cmd("edit " .. vim.fn.fnameescape(path))
	buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "preexisting unsaved" })
	response = dir .. "/preexisting-response"
	Guardian.review({ path = path, original = "before\n", proposed = "proposed\n", response_file = response })
	assert(vim.json.decode(Buffers.read_file(response)).decision == "block")
	assert(Buffers.read_buf_content(buf) == "preexisting unsaved\n")
	assert(Buffers.read_file(path) == "proposed\n")
end)
vim.fn.delete(dir, "rf")
if not ok then
	io.stderr:write(tostring(err) .. "\n")
	vim.cmd("cquit 1")
end
vim.cmd("qa!")
