local M = {}
local notes, next_id = {}, 0
local ns = vim.api.nvim_create_namespace("pi-review-comments")

local function excerpt(buf, first, last)
  return table.concat(vim.api.nvim_buf_get_lines(buf, first - 1, last, false), "\n")
end

local function revision(file)
  return file.rev.commit or (file.rev.stage and "index stage " .. file.rev.stage) or "working tree"
end

function M.context(ctx, first, last, buf)
  if not first then
    return {}
  end
  local path = vim.api.nvim_buf_get_name(buf)
  local location = { buf = buf, first = first, last = last, revision = "working tree" }
  local ok, lib = pcall(require, "diffview.lib")
  local view = ok and lib.get_current_view()
  if view and view.cur_layout then
    for _, win in ipairs(view.cur_layout.windows) do
      local file = win.file
      if file and file.bufnr == buf then
        assert(not file.nulled, "Select source, not an empty diff placeholder")
        path = file.absolute_path
        location.revision = revision(file)
        location.repo = file.adapter.ctx.toplevel
        location.diff_path = file.path
        break
      end
    end
  end
  if path:sub(1, #ctx.root + 1) ~= ctx.root .. "/" then
    assert(path == "" or vim.bo[buf].buftype ~= "", "Selection is outside coordinating task")
    return {}
  end
  location.path = path:sub(#ctx.root + 2)
  location.excerpt = excerpt(buf, first, last)
  if vim.bo[buf].modified then
    location.revision = location.revision .. ", unsaved buffer"
  end
  return location
end

function M.label(note)
  local c = note.location
  return c.path and (c.path .. ":" .. c.first .. "-" .. c.last .. " (" .. c.revision .. ")") or "Task-wide feedback"
end

function M.header(c)
  if not c.path then
    return "## Task-wide feedback\n\n"
  end
  local fence = 3
  for ticks in c.excerpt:gmatch("`+") do
    fence = math.max(fence, #ticks + 1)
  end
  fence = string.rep("`", fence)
  return "## "
    .. vim.json.encode(c.path)
    .. ":"
    .. c.first
    .. "-"
    .. c.last
    .. " ("
    .. c.revision
    .. " at comment creation)\n\n"
    .. fence
    .. "\n"
    .. c.excerpt
    .. "\n"
    .. fence
    .. "\n\n"
end

function M.list(ctx)
  local result = {}
  for _, note in pairs(notes) do
    if not ctx or note.key == ctx.id then
      table.insert(result, note)
    end
  end
  table.sort(result, function(a, b)
    return a.id < b.id
  end)
  return result
end

local function position(note)
  local c = note.location
  if not c.buf or not vim.api.nvim_buf_is_loaded(c.buf) then
    return
  end
  if note.mark then
    local pos = vim.api.nvim_buf_get_extmark_by_id(c.buf, ns, note.mark, { details = true })
    if #pos > 0 then
      return pos[1] + 1, pos[3].end_row
    end
    note.mark = nil
  end
  if c.first and c.last <= vim.api.nvim_buf_line_count(c.buf) and excerpt(c.buf, c.first, c.last) == c.excerpt then
    return c.first, c.last
  end
end

function M.decorate(note)
  local first, last = position(note)
  if not first or not last or last < first then
    return
  end
  -- EOL callouts preserve Diffview's vertical alignment; virtual lines do not.
  note.mark = vim.api.nvim_buf_set_extmark(note.location.buf, ns, first - 1, 0, {
    id = note.mark,
    end_row = last,
    end_col = 0,
    right_gravity = false,
    end_right_gravity = true,
    hl_group = "PiReviewRange",
    hl_eol = true,
    sign_text = "▌",
    sign_hl_group = "PiReviewComment",
    virt_text = { { " 💬 " .. note.text:gsub("\n", " ↵ "), "PiReviewComment" } },
    virt_text_pos = "eol",
  })
end

function M.add(ctx, location, text)
  assert(text:find("%S"), "Add a comment before saving")
  next_id = next_id + 1
  local note = { id = next_id, key = ctx.id, location = location, text = text }
  notes[note.id] = note
  M.decorate(note)
  return note
end

function M.edit(note, text)
  assert(notes[note.id] == note, "Comment was deleted")
  assert(text:find("%S"), "Add a comment before saving")
  note.text = text
  M.decorate(note)
end

function M.delete(note)
  if note.mark and vim.api.nvim_buf_is_valid(note.location.buf) then
    vim.api.nvim_buf_del_extmark(note.location.buf, ns, note.mark)
  end
  notes[note.id] = nil
end

function M.format(items)
  local chunks = {}
  for _, note in ipairs(items) do
    table.insert(chunks, M.header(note.location) .. note.text)
  end
  return table.concat(chunks, "\n\n")
end

local function locate(note, win, buf)
  local c = note.location
  if c.buf ~= buf then
    c.buf, note.mark = buf, nil
  end
  local first, last = position(note)
  if not first or not last or last < first or excerpt(buf, first, last) ~= c.excerpt then
    vim.notify("Comment's source changed; original context is kept in the comment", vim.log.levels.WARN)
    return
  end
  M.decorate(note)
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { first, 0 })
  vim.cmd("normal! zz")
end

function M.jump(note)
  local c = note.location
  if not c.path then
    return
  end
  if c.repo then
    local lib, async = require("diffview.lib"), require("diffview.async")
    local view
    for _, candidate in ipairs(lib.views) do
      if
        candidate.adapter
        and candidate.adapter.ctx.toplevel == c.repo
        and candidate.pi_review_state == note.key
        and candidate.set_file_by_path
        and vim.api.nvim_tabpage_is_valid(candidate.tabpage)
      then
        view = candidate
        if candidate == lib.get_current_view() then
          break
        end
      end
    end
    if not view then
      vim.notify("Reopen /review and its repository to jump to this comment", vim.log.levels.WARN)
      return
    end
    async.void(function()
      vim.api.nvim_set_current_tabpage(view.tabpage)
      async.await(view:set_file_by_path(c.diff_path, false))
      if not view.cur_layout then
        return
      end
      for _, win in ipairs(view.cur_layout.windows) do
        local file = win.file
        if
          file
          and file.path == c.diff_path
          and revision(file) == c.revision:gsub(", unsaved buffer$", "")
          and vim.api.nvim_win_is_valid(win.id)
        then
          locate(note, win.id, file.bufnr)
          return
        end
      end
      vim.notify("Comment's revision is not displayed in this Diffview", vim.log.levels.WARN)
    end)()
  elseif c.buf and vim.api.nvim_buf_is_loaded(c.buf) then
    -- Never replace a Diffview-owned window with an arbitrary source buffer.
    vim.cmd("belowright split")
    vim.api.nvim_win_set_buf(0, c.buf)
    locate(note, vim.api.nvim_get_current_win(), c.buf)
  else
    vim.notify("Source buffer is gone; original context is kept in the comment", vim.log.levels.WARN)
  end
end

function M.open_list(ctx, edit)
  local rows = M.list(ctx)
  if #rows == 0 then
    vim.notify("No pending comments")
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = math.max(1, math.min(100, vim.o.columns - 4)),
    height = math.max(1, math.min(#rows, 12, vim.o.lines - 4)),
    row = 1,
    col = 1,
    title = " Pending comments (memory only) ",
    footer = " Enter: jump · e: edit · d: delete · q: close ",
  })
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  local function render()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    rows = M.list(ctx)
    if #rows == 0 then
      close()
      return
    end
    local lines = {}
    for _, note in ipairs(rows) do
      table.insert(lines, M.label(note) .. " — " .. note.text:gsub("\n", " ↵ "))
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
  end
  local function current()
    return rows[vim.api.nvim_win_get_cursor(win)[1]]
  end
  local function map(key, fn)
    vim.keymap.set("n", key, fn, { buffer = buf, nowait = true })
  end
  map("q", close)
  map("<Esc>", close)
  map("<CR>", function()
    local note = current()
    close()
    M.jump(note)
  end)
  map("e", function()
    edit(current(), render)
  end)
  map("d", function()
    M.delete(current())
    render()
  end)
  render()
  return buf
end

function M.setup()
  vim.api.nvim_set_hl(0, "PiReviewComment", { default = true, fg = "#d7a65f" })
  vim.api.nvim_set_hl(0, "PiReviewRange", { default = true, link = "CursorLine" })
end

return M
