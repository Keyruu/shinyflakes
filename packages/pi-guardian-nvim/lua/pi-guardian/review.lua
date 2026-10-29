local Buffers = require("pi-guardian.buffers")
local Diffopt = require("pi-guardian.diffopt")

local M = {}

-- ── Review state ─────────────────────────────────────────────────────

---@class PiGuardianReviewState
---@field responded boolean
---@field abs_path string
---@field response_file string
---@field orig_buf integer
---@field file_buf integer
---@field left_win integer
---@field right_win integer
---@field review_tab integer
---@field prev_tab integer
---@field prev_diffopt string
---@field disk_content string
---@field save_autocmd integer|nil
---@field file_buf_existed boolean
---@field on_cleanup fun()|nil

---@param state PiGuardianReviewState
---@param decision string "allow" or "block"
---@param content string|nil
local function respond(state, decision, content)
  if state.responded then
    return
  end
  state.responded = true

  local response = { decision = decision }
  if content then
    response.content = content
  end
  Buffers.write_file(state.response_file, vim.json.encode(response))
end

---@param state PiGuardianReviewState
local function close_review_tab(state)
  if state.save_autocmd then
    pcall(vim.api.nvim_del_autocmd, state.save_autocmd)
  end
  for _, buf in ipairs({ state.orig_buf, state.file_buf }) do
    for _, key in ipairs({ "ga", "gx", "g+", "g-", "q", "<Esc>" }) do
      pcall(vim.keymap.del, "n", key, { buffer = buf })
    end
  end
  for _, w in ipairs({ state.left_win, state.right_win }) do
    if vim.api.nvim_win_is_valid(w) then
      vim.wo[w].winbar = ""
    end
  end

  vim.go.diffopt = state.prev_diffopt

  -- Turn off diff mode on both windows
  for _, w in ipairs({ state.left_win, state.right_win }) do
    if vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_win_call(w, function()
        vim.cmd("diffoff")
      end)
    end
  end

  -- Close remaining windows in the review tab. Delete the TabClose
  -- augroup first so our own autocmd doesn't fire during teardown.
  pcall(vim.api.nvim_del_augroup_by_name, "PiGuardianTabClose")
  if vim.api.nvim_tabpage_is_valid(state.review_tab) then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(state.review_tab)) do
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end

  if vim.api.nvim_tabpage_is_valid(state.review_tab) then
    vim.api.nvim_set_current_tabpage(state.review_tab)
    vim.cmd("noautocmd tabclose")
  end

  if vim.api.nvim_tabpage_is_valid(state.prev_tab) then
    vim.api.nvim_set_current_tabpage(state.prev_tab)
  end

  -- Wipe only the buffers this review created (orig scratch + file if new).
  -- Previous approach deleted ALL unknown buffers which raced with queued reviews.
  -- Detach LSP clients before deleting to avoid "Invalid buffer id" errors.
  -- Use vim.defer_fn instead of vim.schedule: LSP startup uses multi-level
  -- scheduling (FileType → schedule(level1) → schedule(start_config)), so a
  -- plain vim.schedule races between those levels and deletes the buffer
  -- before start_config calls vim.fs.root(buf). The defer gives LSP's full
  -- async init chain time to complete.
  vim.defer_fn(function()
    local function safe_delete(b)
      if not vim.api.nvim_buf_is_valid(b) then
        return
      end
      for _, client in pairs(vim.lsp.get_clients({ bufnr = b })) do
        pcall(vim.lsp.buf_detach_client, b, client.id)
      end
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end

    safe_delete(state.orig_buf)
    if not state.file_buf_existed and vim.api.nvim_buf_is_valid(state.file_buf)
      and not vim.bo[state.file_buf].modified and #vim.fn.win_findbuf(state.file_buf) == 0 then
      safe_delete(state.file_buf)
    end
  end, 200)

  if state.on_cleanup then
    state.on_cleanup()
  end
end

-- ── Accept / Reject ──────────────────────────────────────────────────

---@param state PiGuardianReviewState
function M.accept(state)
  if state.responded then
    return
  end

  if Buffers.read_file(state.abs_path) ~= state.disk_content then
    vim.notify("[pi-guardian] File changed on disk; stop review and reconcile edits first", vim.log.levels.WARN)
    return
  end
  local ok, err = pcall(vim.api.nvim_buf_call, state.file_buf, function() vim.cmd("write") end)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
    return
  end
  respond(state, "allow", Buffers.read_buf_content(state.file_buf))
  close_review_tab(state)
end

---@param state PiGuardianReviewState
function M.reject(state)
  if state.responded then
    return
  end

  respond(state, "block")

  close_review_tab(state)
end

-- ── Keybinds ─────────────────────────────────────────────────────────

---@param state PiGuardianReviewState
local function refresh_diff(state)
  for _, w in ipairs({ state.left_win, state.right_win }) do
    if vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_win_call(w, function()
        vim.cmd("diffupdate")
      end)
    end
  end
end

---@param state PiGuardianReviewState
function M.setup_keybinds(state)
  for _, buf in ipairs({ state.orig_buf, state.file_buf }) do
    vim.keymap.set("n", "ga", function()
      M.accept(state)
    end, { buffer = buf, desc = "Guardian: Accept" })

    vim.keymap.set("n", "gx", function()
      M.reject(state)
    end, { buffer = buf, desc = "Guardian: Stop (keep files)" })

    vim.keymap.set("n", "g+", function()
      Diffopt.expand()
      refresh_diff(state)
    end, { buffer = buf, desc = "Guardian: Expand context" })

    vim.keymap.set("n", "g-", function()
      Diffopt.shrink()
      refresh_diff(state)
    end, { buffer = buf, desc = "Guardian: Shrink context" })
  end
end

-- ── Autocmds ─────────────────────────────────────────────────────────

---@param state PiGuardianReviewState
function M.setup_autocmds(state)
  -- Saving is not acceptance; remember explicit human saves for the conflict check.
  state.save_autocmd = vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = state.file_buf,
    callback = function()
      state.disk_content = Buffers.read_file(state.abs_path)
    end,
  })

  -- If the review tab is closed without a decision, reject
  local group = vim.api.nvim_create_augroup("PiGuardianTabClose", { clear = true })
  vim.api.nvim_create_autocmd("TabClosed", {
    group = group,
    callback = function()
      if not vim.api.nvim_tabpage_is_valid(state.review_tab) then
        vim.api.nvim_del_augroup_by_id(group)
        vim.schedule(function()
          M.reject(state)
        end)
      end
    end,
  })
end

return M
