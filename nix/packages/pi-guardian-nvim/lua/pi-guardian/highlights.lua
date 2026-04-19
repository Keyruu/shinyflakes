local M = {}

M.DIFF_WINHIGHLIGHT = "WinBar:PiGuardianWinbar,WinBarNC:PiGuardianWinbar"

local initialized = false

function M.ensure()
  if initialized then
    return
  end
  initialized = true

  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local warning = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn", link = false })

  -- Fallbacks are Tokyo Night colors — only used if the colorscheme
  -- doesn't define DiagnosticWarn / Normal highlight groups.
  local bar_bg = warning.fg or 0xe0af68
  local bar_fg = normal.bg or 0x1a1b26

  vim.api.nvim_set_hl(0, "PiGuardianWinbar", { default = true, bg = bar_bg })
  vim.api.nvim_set_hl(0, "PiGuardianWinbarLabel", { default = true, fg = bar_fg, bg = bar_bg, bold = true })
  vim.api.nvim_set_hl(0, "PiGuardianWinbarHint", { default = true, fg = bar_fg, bg = bar_bg })
end

--- Build winbar strings for the diff panes.
---@param rel_path string
---@return string left_winbar, string right_winbar
function M.build_winbars(rel_path)
  local left = "%#PiGuardianWinbar# %#PiGuardianWinbarLabel#ORIGINAL: " .. rel_path .. "%#PiGuardianWinbar#"

  local right = "%#PiGuardianWinbar# %#PiGuardianWinbarLabel#PROPOSED: " .. rel_path .. " %#PiGuardianWinbar# %#PiGuardianWinbarHint#[ga=accept  gx=reject  g+/g-=context]%#PiGuardianWinbar#"

  return left, right
end

return M
