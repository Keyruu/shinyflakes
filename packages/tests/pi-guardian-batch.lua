vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/packages/pi-guardian-nvim")
local batch = require("pi-guardian.batch")
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local source = dir .. "/source"
vim.fn.writefile({ "human content" }, source)
vim.cmd("edit " .. vim.fn.fnameescape(source))
local source_buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, { "unsaved human edit" })
local function check(action, expected)
  local response = dir .. "/" .. action .. ".json"
  local payload = dir .. "/payload.json"
  vim.fn.writefile({ vim.json.encode({ text = "diff --git a/source b/source\n-old\n+new", response_file = response }) }, payload)
  batch.from_file(payload)
  assert(vim.fn.filereadable(payload) == 0)
  assert(vim.bo.filetype == "diff" and not vim.bo.modifiable)
  batch.close("unrelated-instance")
  assert(vim.fn.filereadable(response) == 0)
  if action == "close-tab" then
    vim.cmd("tabclose")
  elseif action == "external" then
    batch.close(response)
  else
    vim.fn.maparg(action, "n", false, true).callback()
  end
  assert(vim.wait(1000, function() return vim.fn.filereadable(response) == 1 end))
  local result = vim.json.decode(table.concat(vim.fn.readfile(response), "\n"))
  assert(result.decision == expected, vim.inspect(result))
  assert(vim.fn.readfile(source)[1] == "human content")
  assert(vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)[1] == "unsaved human edit")
  assert(vim.bo[source_buf].modified)
end
check("ga", "accept")
check("gx", "changes")
check("gq", "pause")
check("close-tab", "pause")
check("external", "pause")
local previous = vim.api.nvim_get_current_tabpage()
local response = dir .. "/missing-owner/response.json"
batch.open({ text = "Pending after restart", response_file = response })
batch.close(response)
assert(vim.api.nvim_get_current_tabpage() == previous)
vim.fn.delete(dir, "rf")
print("Guardian batch: native Neovim actions, close/reopen, IPC ownership, and human edits preserved")
vim.cmd("qa!")
