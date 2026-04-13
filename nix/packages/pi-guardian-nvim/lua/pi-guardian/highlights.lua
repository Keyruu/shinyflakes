local M = {}

M.DIFF_WINHIGHLIGHT = "WinBar:PiGuardianWinbar,WinBarNC:PiGuardianWinbar"

local initialized = false

function M.ensure()
  if initialized then
    return
  end
  initialized = true

  local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local warning = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn", link = false })

  -- Fallbacks are Tokyo Night colors — only used if the colorscheme
  -- doesn't define DiagnosticWarn / Normal highlight groups.
  local bar_bg = warning.fg or 0xe0af68
  local bar_fg = normal.bg or 0x1a1b26

  vim.api.nvim_set_hl(0, "PiGuardianWinbar", { default = true, bg = bar_bg })
  vim.api.nvim_set_hl(0, "PiGuardianWinbarLabel", { default = true, fg = bar_fg, bg = bar_bg, bold = true })
  vim.api.nvim_set_hl(0, "PiGuardianWinbarHint", { default = true, fg = bar_fg, bg = bar_bg })
  vim.api.nvim_set_hl(
    0,
    "PiGuardianWinbarReason",
    { default = true, fg = comment.fg or 0x565f89, bg = bar_bg, italic = true }
  )
end

local MAX_REASON_LEN = 60

--- Build winbar strings for the diff panes.
---@param rel_path string
---@param reason string|nil
---@return string left_winbar, string right_winbar
function M.build_winbars(rel_path, reason)
  local left = "%#PiGuardianWinbar# %#PiGuardianWinbarLabel#ORIGINAL: " .. rel_path .. "%#PiGuardianWinbar#"

  local right_parts = {
    "%#PiGuardianWinbar# %#PiGuardianWinbarLabel#PROPOSED: " .. rel_path,
    " %#PiGuardianWinbar# %#PiGuardianWinbarHint#[ga=accept  gx=reject  g+/g-=context]",
  }

  if reason and reason ~= "" then
    local display = #reason > MAX_REASON_LEN and (reason:sub(1, MAX_REASON_LEN - 1) .. "…") or reason
    right_parts[#right_parts + 1] = " %#PiGuardianWinbarReason#" .. display
  end

  right_parts[#right_parts + 1] = "%#PiGuardianWinbar#"
  return left, table.concat(right_parts)
end

return M
