--- pi-guardian.nvim — Diff review for pi tool-guardian extension.
---
--- Architecture:
---   Left pane:  scratch buffer with ORIGINAL content (readonly, no LSP)
---   Right pane: the ACTUAL file with PROPOSED changes (full LSP, gitsigns)
---
--- On accept: file already has correct content, close diff tab.
--- On reject: restore original content to the file buffer.
---
--- Communication with the extension is via JSON files in /tmp:
---   payload.json  → extension writes (original, proposed, path, reason)
---   response.json ← plugin writes (decision, content if modified)

local Buffers = require("pi-guardian.buffers")
local Diffopt = require("pi-guardian.diffopt")
local Highlights = require("pi-guardian.highlights")
local Modal = require("pi-guardian.modal")
local Review = require("pi-guardian.review")

local M = {}

local DIFF_SETTLE_MS = 200

--- Reject hook for the extension to call when TUI wins the race.
--- Set by review(), cleared on accept/reject.
--- Only one review can be active at a time (serialized by the TS review queue).
---@type fun()|nil
M._active_reject = nil

--- Reject hook for modal approval when TUI wins the race.
--- If a new modal opens while one is already active, the old one is
--- dismissed first (see approve_from_file below).
---@type fun()|nil
M._active_modal_reject = nil

---@class PiGuardianPayload
---@field path string absolute path to the file
---@field original string original file content
---@field proposed string proposed file content
---@field reason string|nil reason for the change
---@field response_file string path to write response JSON

--- Open a diff review tab.
---@param payload PiGuardianPayload
function M.review(payload)
  Highlights.ensure()

  local original_lines, original_eol = Buffers.split_content(payload.original)
  local proposed_lines, proposed_eol = Buffers.split_content(payload.proposed)
  local rel_path = vim.fn.fnamemodify(payload.path, ":~:.")

  local prev_diffopt = vim.go.diffopt
  Diffopt.set_context(Diffopt.DEFAULT_CONTEXT)

  -- Track whether the file buffer existed before we open it
  local file_buf_existed = false
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b) == payload.path then
      file_buf_existed = true
      break
    end
  end

  local prev_tab = vim.api.nvim_get_current_tabpage()

  -- Open the file directly in a new tab — no throwaway buffer created
  vim.cmd("tab split " .. vim.fn.fnameescape(payload.path))
  local review_tab = vim.api.nvim_get_current_tabpage()
  local right_win = vim.api.nvim_get_current_win()
  local file_buf = vim.api.nvim_win_get_buf(right_win)

  -- Left: open scratch buffer in a split without creating any throwaway buffer
  local orig_buf = Buffers.create_original_buf(payload.path, original_lines, original_eol)
  local left_win = vim.api.nvim_open_win(orig_buf, false, { split = "left" })
  local file_was_modified = vim.bo[file_buf].modified

  vim.bo[file_buf].modifiable = true
  vim.api.nvim_buf_set_lines(file_buf, 0, -1, false, proposed_lines)
  vim.bo[file_buf].eol = proposed_eol
  vim.bo[file_buf].modified = true

  -- Configure windows
  Buffers.reset_win_options(left_win)
  Buffers.reset_win_options(right_win)
  vim.cmd("wincmd =")

  local left_bar, right_bar = Highlights.build_winbars(rel_path)
  vim.wo[left_win].winbar = left_bar
  vim.wo[right_win].winbar = right_bar

  -- Enable diff
  vim.api.nvim_set_current_win(left_win)
  vim.cmd("diffthis")
  vim.api.nvim_set_current_win(right_win)
  vim.cmd("diffthis")

  -- Jump to first change after render settles
  vim.defer_fn(function()
    if not vim.api.nvim_tabpage_is_valid(review_tab) then
      return
    end
    if vim.api.nvim_win_is_valid(left_win) then
      vim.api.nvim_win_call(left_win, function()
        vim.cmd("diffthis")
      end)
    end
    if vim.api.nvim_win_is_valid(right_win) then
      vim.api.nvim_set_current_win(right_win)
      pcall(vim.cmd, "normal! gg]c")
      vim.cmd("syncbind")
    end
  end, DIFF_SETTLE_MS)

  -- Show reason as a floating popup (dismiss with q/Esc)
  if payload.reason and payload.reason ~= "" then
    local MAX_WIDTH = 90
    local lines = {}
    local current = ""
    for word in payload.reason:gmatch("%S+") do
      if #current + #word + 1 > MAX_WIDTH and current ~= "" then
        lines[#lines + 1] = current
        current = word
      else
        current = current == "" and word or (current .. " " .. word)
      end
    end
    if current ~= "" then
      lines[#lines + 1] = current
    end

    local popup_w = 0
    for _, l in ipairs(lines) do
      local len = vim.fn.strdisplaywidth(l)
      if len > popup_w then popup_w = len end
    end
    popup_w = math.min(popup_w + 4, math.floor(vim.o.columns * 0.8))

    local buf = vim.api.nvim_create_buf(false, true)
    local display_lines = { "  📝 Why:" }
    for _, l in ipairs(lines) do
      display_lines[#display_lines + 1] = "  " .. l
    end
    display_lines[#display_lines + 1] = ""
    display_lines[#display_lines + 1] = "  Press q or Esc to dismiss"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "pi-guardian-reason"

    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      row = math.floor((vim.o.lines - #display_lines) / 2),
      col = math.floor((vim.o.columns - popup_w) / 2),
      width = popup_w,
      height = #display_lines,
      style = "minimal",
      border = "rounded",
      title = " reason ",
      title_pos = "center",
      noautocmd = true,
      zindex = 50,
    })
    vim.wo[win].winhl = "FloatBorder:DiagnosticWarn,NormalFloat:Normal"
    vim.wo[win].cursorline = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"

    for _, b in ipairs({ buf, file_buf, orig_buf }) do
      vim.keymap.set("n", "q", function()
        if vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end, { buffer = b, nowait = true })
      vim.keymap.set("n", "<Esc>", function()
        if vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end, { buffer = b, nowait = true })
    end

    -- Auto-cleanup: wipe buffer when window closes
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      once = true,
      callback = function()
        -- Remove q/Esc mappings from diff buffers when popup closes
        for _, b in ipairs({ file_buf, orig_buf }) do
          if vim.api.nvim_buf_is_valid(b) then
            pcall(vim.keymap.del, "n", "q", { buffer = b })
            pcall(vim.keymap.del, "n", "<Esc>", { buffer = b })
          end
        end
      end,
    })
  end

  -- Build review state
  ---@type PiGuardianReviewState
  local state = {
    responded = false,
    abs_path = payload.path,
    response_file = payload.response_file,
    orig_buf = orig_buf,
    file_buf = file_buf,
    left_win = left_win,
    right_win = right_win,
    review_tab = review_tab,
    prev_tab = prev_tab,
    prev_diffopt = prev_diffopt,
    original_lines = original_lines,
    original_eol = original_eol,
    file_was_modified = file_was_modified,
    file_buf_existed = file_buf_existed,
    on_cleanup = function()
      M._active_reject = nil
    end,
  }

  Review.setup_keybinds(state)
  Review.setup_autocmds(state)

  M._active_reject = function()
    Review.reject(state)
  end
end

--- Open an approval modal from a JSON payload file.
---@param payload_file string path to JSON payload file
function M.approve_from_file(payload_file)
  -- Dismiss any existing modal before opening a new one
  if M._active_modal_reject then
    M._active_modal_reject()
  end

  local raw = Buffers.read_file(payload_file)
  if raw == "" then
    return
  end
  local ok, payload = pcall(vim.json.decode, raw)
  if not ok or not payload then
    return
  end
  pcall(os.remove, payload_file)

  local state = Modal.open(payload)
  state.on_cleanup = function()
    M._active_modal_reject = nil
  end

  M._active_modal_reject = function()
    Modal.block(state)
  end
end

--- Open a diff review from a JSON payload file.
---@param payload_file string path to JSON payload file
function M.review_from_file(payload_file)
  local raw = Buffers.read_file(payload_file)
  if raw == "" then
    return
  end
  local ok, payload = pcall(vim.json.decode, raw)
  if not ok or not payload then
    return
  end
  pcall(os.remove, payload_file)
  M.review(payload)
end

return M
