local Highlights = require("pi-guardian.highlights")

local M = {}

-- ── File I/O ─────────────────────────────────────────────────────────

---@param path string
---@return string
function M.read_file(path)
  local f = io.open(path, "r")
  if not f then
    return ""
  end
  local content = f:read("*a")
  f:close()
  return content
end

---@param path string
---@param content string
function M.write_file(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = io.open(path, "w")
  if not f then
    vim.notify("[pi-guardian] failed to write: " .. path, vim.log.levels.ERROR)
    return
  end
  f:write(content)
  f:close()
end

---@param abs_path string
function M.reload_buf(abs_path)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b) == abs_path then
      vim.api.nvim_buf_call(b, function()
        vim.cmd("edit!")
      end)
    end
  end
end

-- ── Content helpers ──────────────────────────────────────────────────

--- Split content into lines and detect trailing EOL.
--- Neovim represents trailing newlines via the buffer `eol` option, not
--- as a visible empty line — strip the trailing "" that vim.split produces.
---@param content string
---@return string[] lines, boolean has_eol
function M.split_content(content)
  local lines = vim.split(content, "\n", { plain = true })
  local has_eol = #lines > 0 and lines[#lines] == ""
  if has_eol then
    table.remove(lines)
  end
  return lines, has_eol
end

--- Read final content from a buffer, respecting its EOL setting.
---@param buf integer
---@return string
function M.read_buf_content(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if vim.bo[buf].eol then
    lines[#lines + 1] = ""
  end
  return table.concat(lines, "\n")
end

-- ── Buffer/window setup ──────────────────────────────────────────────

---@param win integer
function M.reset_win_options(win)
  vim.wo[win].number = true
  vim.wo[win].relativenumber = vim.go.relativenumber
  vim.wo[win].signcolumn = "no"
  vim.wo[win].conceallevel = 0
  vim.wo[win].concealcursor = ""
  vim.wo[win].wrap = vim.go.wrap
  vim.wo[win].linebreak = vim.go.linebreak
  vim.wo[win].list = vim.go.list
  vim.wo[win].cursorline = vim.go.cursorline
  vim.wo[win].winfixbuf = false
  vim.wo[win].winhighlight = Highlights.DIFF_WINHIGHLIGHT
  vim.wo[win].foldcolumn = "0"
end

--- Create a readonly scratch buffer with the original file content.
---@param abs_path string
---@param lines string[]
---@param has_eol boolean
---@return integer buf
function M.create_original_buf(abs_path, lines, has_eol)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].eol = has_eol
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  -- Clean up stale buffer from a crashed previous review
  local buf_name = "pi-guardian://original/" .. abs_path
  local stale = vim.fn.bufnr(buf_name)
  if stale ~= -1 then
    vim.api.nvim_buf_delete(stale, { force = true })
  end
  vim.api.nvim_buf_set_name(buf, buf_name)

  local ft = vim.filetype.match({ filename = abs_path }) or ""
  if ft ~= "" then
    vim.bo[buf].filetype = ft
  end
  return buf
end

return M
