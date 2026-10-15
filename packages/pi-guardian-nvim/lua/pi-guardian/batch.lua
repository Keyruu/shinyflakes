local M = {}
local active = {}

function M.close(response_file)
  local close = active[response_file]
  if close then close("pause") end
end

function M.open(payload)
  local previous = vim.api.nvim_get_current_tabpage()
  vim.cmd("tabnew")
  local tab = vim.api.nvim_get_current_tabpage()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(payload.text, "\n", { plain = true }))
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = false
  vim.wo.winbar = "Checkpoint: since accepted | ga accept | gx request changes | gq pause (files kept)"
  local group = vim.api.nvim_create_augroup("PiGuardianBatch" .. buf, { clear = true })
  local responded = false
  local function finish(decision)
    if responded then return end
    responded = true
    active[payload.response_file] = nil
    vim.api.nvim_del_augroup_by_id(group)
    local file = io.open(payload.response_file, "w")
    if file then
      file:write(vim.json.encode({ decision = decision }))
      file:close()
    else
      vim.notify("Review owner unavailable; checkpoint stays pending. Reopen /review.", vim.log.levels.WARN)
    end
    if vim.api.nvim_tabpage_is_valid(tab) then
      vim.api.nvim_set_current_tabpage(tab)
      vim.cmd("tabclose")
    end
    if vim.api.nvim_tabpage_is_valid(previous) then
      vim.api.nvim_set_current_tabpage(previous)
    end
  end
  active[payload.response_file] = finish
  for key, decision in pairs({ ga = "accept", gx = "changes", gq = "pause" }) do
    vim.keymap.set("n", key, function() finish(decision) end, { buffer = buf })
  end
  vim.api.nvim_create_autocmd("TabClosed", {
    group = group,
    callback = function()
      if not vim.api.nvim_tabpage_is_valid(tab) then finish("pause") end
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function() finish("pause") end,
  })
end

function M.from_file(path)
  local file = assert(io.open(path, "r"))
  local payload = vim.json.decode(file:read("*a"))
  file:close()
  os.remove(path)
  M.open(payload)
end

return M
