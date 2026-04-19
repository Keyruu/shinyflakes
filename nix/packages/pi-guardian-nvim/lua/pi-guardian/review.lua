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
---@field original_lines string[]
---@field original_eol boolean
---@field file_was_modified boolean
---@field file_buf_existed boolean
---@field bufs_before table<integer, boolean>
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

  -- Wipe any buffers created during the review (scratch, orphans from tab ops).
  -- File buffer is kept if it existed before review.
  -- Detach LSP clients before deleting to avoid "Invalid buffer id" errors.
  vim.schedule(function()
    local function safe_delete(b)
      if not vim.api.nvim_buf_is_valid(b) then
        return
      end
      for _, client in pairs(vim.lsp.get_clients({ bufnr = b })) do
        pcall(vim.lsp.buf_detach_client, b, client.id)
      end
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end

    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if not state.bufs_before[b] and b ~= state.file_buf then
        safe_delete(b)
      end
    end
    if not state.file_buf_existed then
      safe_delete(state.file_buf)
    end
  end)

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

  local final_content = Buffers.read_buf_content(state.file_buf)
  Buffers.write_file(state.abs_path, final_content)
  respond(state, "allow", final_content)
  close_review_tab(state)
  Buffers.reload_buf(vim.fn.fnamemodify(state.abs_path, ":p"))
end

---@param state PiGuardianReviewState
function M.reject(state)
  if state.responded then
    return
  end

  respond(state, "block")

  if vim.api.nvim_buf_is_valid(state.file_buf) then
    vim.bo[state.file_buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.file_buf, 0, -1, false, state.original_lines)
    vim.bo[state.file_buf].eol = state.original_eol
    vim.bo[state.file_buf].modified = state.file_was_modified
  end

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
    end, { buffer = buf, desc = "Guardian: Reject" })

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
  -- :w on the file buffer triggers accept
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = state.file_buf,
    once = true,
    callback = function()
      M.accept(state)
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
