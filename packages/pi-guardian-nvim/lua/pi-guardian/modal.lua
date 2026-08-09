--- Floating modal for tool call approval.
---
--- Shows tool info in a centered floating window with keybinds:
---   ga — Allow
---   gx — Block
---   gR — Allow + Remember
---
--- Communication with the extension is via JSON files in /tmp:
---   payload.json  → extension writes (tool_name, display, dangerous, response_file)
---   response.json ← plugin writes (decision: "allow" | "allow_remember" | "block")

local Buffers = require("pi-guardian.buffers")
local Highlights = require("pi-guardian.highlights")

local M = {}

---@class PiGuardianApprovalPayload
---@field tool_name string
---@field display string what to show the user (command, tool info, etc.)
---@field dangerous boolean whether this is a dangerous command
---@field response_file string path to write response JSON

---@class PiGuardianModalState
---@field responded boolean
---@field response_file string
---@field buf integer
---@field win integer
---@field on_cleanup fun()|nil

---@param state PiGuardianModalState
---@param decision string
local function respond(state, decision)
  if state.responded then
    return
  end
  state.responded = true
  Buffers.write_file(state.response_file, vim.json.encode({ decision = decision }))
end

---@param state PiGuardianModalState
local function close_modal(state)
  if vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  if vim.api.nvim_buf_is_valid(state.buf) then
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
  end
  if state.on_cleanup then
    state.on_cleanup()
  end
end

---@param state PiGuardianModalState
function M.allow(state)
  if state.responded then
    return
  end
  respond(state, "allow")
  close_modal(state)
end

---@param state PiGuardianModalState
function M.allow_remember(state)
  if state.responded then
    return
  end
  respond(state, "allow_remember")
  close_modal(state)
end

---@param state PiGuardianModalState
function M.block(state)
  if state.responded then
    return
  end
  respond(state, "block")
  close_modal(state)
end

--- Build the lines to display in the modal.
---@param payload PiGuardianApprovalPayload
---@return string[]
local function build_lines(payload)
  local lines = {}
  local icon = payload.dangerous and "⚠️  DANGEROUS" or "🔍 Review"
  table.insert(lines, icon .. " — " .. payload.tool_name)
  table.insert(lines, "")

  for line in payload.display:gmatch("[^\n]+") do
    table.insert(lines, "  " .. line)
  end

  table.insert(lines, "")
  table.insert(lines, "  ga = Allow    gx = Block    gR = Allow + Remember")
  return lines
end

--- Calculate window dimensions from content lines.
---@param lines string[]
---@return integer width, integer height
local function calc_dimensions(lines)
  local max_width = 40
  for _, line in ipairs(lines) do
    local len = vim.fn.strdisplaywidth(line)
    if len > max_width then
      max_width = len
    end
  end
  -- clamp width
  local editor_width = vim.o.columns
  local width = math.min(max_width + 4, math.floor(editor_width * 0.8))
  local height = #lines
  return width, height
end

--- Open the approval modal.
---@param payload PiGuardianApprovalPayload
---@return PiGuardianModalState
function M.open(payload)
  Highlights.ensure()

  local lines = build_lines(payload)
  local width, height = calc_dimensions(lines)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local border_hl = payload.dangerous and "DiagnosticError" or "DiagnosticWarn"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " pi-guardian ",
    title_pos = "center",
    noautocmd = true,
  })

  vim.wo[win].winhl = "FloatBorder:" .. border_hl .. ",NormalFloat:Normal"
  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  ---@type PiGuardianModalState
  local state = {
    responded = false,
    response_file = payload.response_file,
    buf = buf,
    win = win,
    on_cleanup = nil,
  }

  -- Keybinds
  local opts = { buffer = buf, nowait = true }
  vim.keymap.set("n", "ga", function()
    M.allow(state)
  end, opts)
  vim.keymap.set("n", "gx", function()
    M.block(state)
  end, opts)
  vim.keymap.set("n", "gR", function()
    M.allow_remember(state)
  end, opts)
  vim.keymap.set("n", "<Esc>", function()
    M.block(state)
  end, opts)
  vim.keymap.set("n", "q", function()
    M.block(state)
  end, opts)

  -- If window is closed without decision, block
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if not state.responded then
          respond(state, "block")
        end
        if state.on_cleanup then
          state.on_cleanup()
        end
      end)
    end,
  })

  return state
end

return M
