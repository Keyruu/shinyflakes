local function is_codecompanion_chat_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  -- Option 1: Check by filetype (REPLACE 'codecompanion_ft' with the actual filetype)
  local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  if ft == "codecompanion" then
    return true
  end

  return false
end

-- Custom Lualine component function
local function codecompanion_modifiable_status()
  local current_bufnr = vim.api.nvim_get_current_buf()
  if is_codecompanion_chat_buffer(current_bufnr) then
    if not vim.api.nvim_get_option_value("modifiable", { buf = current_bufnr }) then
      return "✨ Working on an answer..."
    else
      return "📝 Ask me anything!" -- Or perhaps '✏️' to indicate editable
    end
  end
  return ""
end

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_x, 2, codecompanion_modifiable_status)
  end,
}
