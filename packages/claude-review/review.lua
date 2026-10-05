-- claude-review: diff tab for reviewing an agent's changes since a baseline tree.
--
-- Loaded with dofile() over RPC by the claude-review CLI, so it carries no
-- plugin state of its own; the active review lives in _G.__claude_review so a
-- re-dofile'd copy can still cancel it.
--
-- Layout: left = baseline (readonly scratch), right = the real file, both in
-- diff mode, plus a location list of every hunk. Feedback:
--   <leader>rc  comment on the line / visual range (either side)
--   ai: ...     inline comment typed into the file, stripped on finish
--   direct edits to the file, reported back as a diff
--   <leader>rd  finish (prompts for an overall comment)
--   <leader>rq  cancel

local M = {}

local NS = vim.api.nvim_create_namespace("claude-review")
local AUGROUP = "ClaudeReview"

local function git(root, args)
  local cmd = { "git", "-C", root }
  vim.list_extend(cmd, args)
  local r = vim.system(cmd, { text = true }):wait()
  return r.code == 0 and r.stdout or nil
end

local function split(content)
  local lines = vim.split(content, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

local function tree_lines(root, tree, path)
  local out = git(root, { "show", tree .. ":" .. path })
  return out and split(out) or {}
end

--- Location-list items for every hunk between two trees.
local function hunk_items(st)
  local args = { "diff", "-U0", "--no-color", "--no-renames", st.base, st.proposed, "--" }
  vim.list_extend(args, st.files)
  local out = git(st.root, args) or ""
  local items, old_path, path = {}, nil, nil
  for line in vim.gsplit(out, "\n", { plain = true }) do
    if line:match("^%-%-%- ") then
      old_path = line:match("^%-%-%- a/(.*)$")
    elseif line:match("^%+%+%+ ") then
      path = line:match("^%+%+%+ b/(.*)$") or old_path
    elseif path and line:match("^@@") then
      local dc, start, ac, ctx = line:match("^@@ %-%d+,?(%d*) %+(%d+),?(%d*) @@ ?(.*)$")
      if start then
        local removed = dc == "" and 1 or tonumber(dc)
        local added = ac == "" and 1 or tonumber(ac)
        table.insert(items, {
          filename = st.root .. "/" .. path,
          lnum = math.max(tonumber(start), 1),
          text = string.format("+%d -%d %s", added, removed, ctx),
        })
      end
    end
  end
  return items
end

--- Sidebar rendering: the path on a file's first hunk, indented hunks after.
--- Global because quickfixtextfunc needs a v:lua-reachable name.
function _G._claude_review_qftf(info)
  local items = vim.fn.getloclist(info.winid, { id = info.id, items = 1 }).items
  local st = _G.__claude_review
  local prefix = st and (st.root .. "/") or ""
  local out = {}
  for i = info.start_idx, info.end_idx do
    local it = items[i]
    local name = vim.api.nvim_buf_get_name(it.bufnr)
    local rel = name:sub(1, #prefix) == prefix and name:sub(#prefix + 1) or name
    local stats = it.text:match("^(%+%d+ %-%d+)") or it.text
    local hunk = string.format("L%-4d %s", it.lnum, stats)
    local prev_name = i > 1 and vim.api.nvim_buf_get_name(items[i - 1].bufnr) or nil
    if name ~= prev_name then
      table.insert(out, rel .. "  " .. hunk)
    else
      table.insert(out, "  └ " .. hunk)
    end
  end
  return out
end

local function file_index(st, abs)
  for i, f in ipairs(st.files) do
    if st.root .. "/" .. f == abs then
      return i
    end
  end
end

local function set_winbars(st)
  local rel = st.files[st.idx]
  local hint = "]f/[f file  ]c/[c hunk  <leader>rc comment  <leader>rd done  <leader>rq cancel"
  local title = st.title ~= "" and (st.title .. "  ") or ""
  if vim.api.nvim_win_is_valid(st.base_win) then
    vim.wo[st.base_win].winbar = "%#DiffDelete# BASE %* " .. rel
  end
  if vim.api.nvim_win_is_valid(st.file_win) then
    vim.wo[st.file_win].winbar = string.format(
      "%%#DiffAdd# CLAUDE %%* %s[%d/%d] %s  %%#Comment#%s",
      title,
      st.idx,
      #st.files,
      rel,
      hint
    )
  end
end

local function render_comments(st, buf)
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  local name = vim.api.nvim_buf_get_name(buf)
  for _, c in ipairs(st.comments) do
    local target = c.side == "base" and st.base_bufs[c.file] or st.root .. "/" .. c.file
    if target == buf or target == name then
      pcall(vim.api.nvim_buf_set_extmark, buf, NS, c.end_line - 1, 0, {
        virt_lines = { { { "  💬 " .. c.text, "DiagnosticInfo" } } },
      })
    end
  end
end

local function map_review_keys(st, buf)
  local o = function(desc)
    return { buffer = buf, desc = "Claude review: " .. desc }
  end
  vim.keymap.set("n", "]f", function() M.goto_file(st.idx + 1) end, o("next file"))
  vim.keymap.set("n", "[f", function() M.goto_file(st.idx - 1) end, o("previous file"))
  vim.keymap.set({ "n", "x" }, "<leader>rc", M.comment, o("comment"))
  vim.keymap.set("n", "<leader>rd", M.finish, o("done"))
  vim.keymap.set("n", "<leader>rq", function() M.close("cancelled") end, o("cancel"))
end

--- Pair the buffer in the right window with a fresh baseline scratch buffer.
local function pair(st, idx)
  st.idx = idx
  local rel = st.files[idx]
  local file_buf = vim.api.nvim_win_get_buf(st.file_win)

  local base = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(base, 0, -1, false, tree_lines(st.root, st.base, rel))
  vim.bo[base].bufhidden = "wipe"
  vim.bo[base].modifiable = false
  vim.bo[base].filetype = vim.filetype.match({ filename = rel }) or ""
  pcall(vim.api.nvim_buf_set_name, base, "claude-review://base/" .. rel)
  st.base_bufs[rel] = base

  for _, w in ipairs({ st.base_win, st.file_win }) do
    vim.api.nvim_win_call(w, function() vim.cmd("diffoff") end)
  end
  vim.api.nvim_win_set_buf(st.base_win, base)
  for _, w in ipairs({ st.base_win, st.file_win }) do
    vim.api.nvim_win_call(w, function() vim.cmd("diffthis") end)
  end

  map_review_keys(st, base)
  map_review_keys(st, file_buf)
  st.touched[file_buf] = true
  render_comments(st, base)
  render_comments(st, file_buf)
  set_winbars(st)
end

function M.goto_file(idx)
  local st = _G.__claude_review
  if not st or idx < 1 or idx > #st.files then
    return
  end
  vim.api.nvim_set_current_win(st.file_win)
  vim.cmd("edit " .. vim.fn.fnameescape(st.root .. "/" .. st.files[idx]))
  -- BufWinEnter pairs it; pair explicitly when the buffer was already shown.
  if st.idx ~= idx then
    pair(st, idx)
  end
  vim.cmd("normal! gg]c")
end

function M.comment()
  local st = _G.__claude_review
  if not st then
    return
  end
  local mode = vim.fn.mode()
  local l1, l2 = vim.fn.line("."), vim.fn.line(".")
  if mode == "v" or mode == "V" or mode == "\22" then
    l1, l2 = vim.fn.line("v"), vim.fn.line(".")
    if l1 > l2 then
      l1, l2 = l2, l1
    end
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  end
  local buf = vim.api.nvim_get_current_buf()
  local side = vim.api.nvim_get_current_win() == st.base_win and "base" or "new"
  local code = table.concat(vim.api.nvim_buf_get_lines(buf, l1 - 1, l2, false), "\n")
  local rel = st.files[st.idx]
  vim.ui.input({ prompt = string.format("Comment %s:%d: ", rel, l1) }, function(text)
    if not text or text == "" then
      return
    end
    table.insert(st.comments, {
      file = rel,
      line = l1,
      end_line = l2,
      side = side,
      source = "keymap",
      text = text,
      code = code,
    })
    render_comments(st, buf)
  end)
end

--- Pull `ai:` lines the user typed (absent from the proposed version) out of
--- every touched buffer, record them as comments, and save the buffers.
local function harvest_inline(st)
  for buf in pairs(st.touched) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local abs = vim.api.nvim_buf_get_name(buf)
      local idx = file_index(st, abs)
      if idx then
        local rel = st.files[idx]
        local proposed = {}
        for _, l in ipairs(tree_lines(st.root, st.proposed, rel)) do
          proposed[l] = true
        end
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local kept, found = {}, {}
        for _, l in ipairs(lines) do
          local text = not proposed[l] and l:match("%f[%w]ai:%s*(.+)$")
          if text then
            -- Anchor to the line that follows the comment once it is gone.
            local line = #kept + 1
            table.insert(found, {
              file = rel,
              line = line,
              end_line = line,
              side = "new",
              source = "inline",
              text = vim.trim(text),
            })
          else
            table.insert(kept, l)
          end
        end
        for _, c in ipairs(found) do
          c.code = kept[c.line] or ""
          table.insert(st.comments, c)
        end
        if #found > 0 then
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, kept)
        end
        if vim.bo[buf].modified then
          vim.api.nvim_buf_call(buf, function() vim.cmd("silent write") end)
        end
      end
    end
  end
end

local function respond(st, status, general)
  local data = vim.json.encode({
    status = status,
    general = general or "",
    comments = #st.comments > 0 and st.comments or vim.NIL,
    files = st.files,
  })
  local tmp = st.response .. ".tmp"
  local f = assert(io.open(tmp, "w"))
  f:write(data)
  f:close()
  os.rename(tmp, st.response)
end

function M.close(status, general)
  local st = _G.__claude_review
  if not st then
    return
  end
  _G.__claude_review = nil
  pcall(vim.api.nvim_del_augroup_by_name, AUGROUP)
  if status ~= "done" then
    st.comments = {}
  end
  respond(st, status, general)
  for buf in pairs(st.touched) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
      for _, k in ipairs({ "]f", "[f", "<leader>rc", "<leader>rd", "<leader>rq" }) do
        pcall(vim.keymap.del, "n", k, { buffer = buf })
      end
      pcall(vim.keymap.del, "x", "<leader>rc", { buffer = buf })
    end
  end
  if vim.api.nvim_tabpage_is_valid(st.tab) and #vim.api.nvim_list_tabpages() > 1 then
    local nr = vim.api.nvim_tabpage_get_number(st.tab)
    pcall(vim.cmd, "tabclose " .. nr)
  end
  -- Drop file buffers the review opened (including the unlisted ones the
  -- location list creates), unless they now show elsewhere or hold unsaved
  -- edits. Buffers the user had open before stay.
  local bufs = vim.deepcopy(st.touched)
  for _, f in ipairs(st.files) do
    local b = vim.fn.bufnr(st.root .. "/" .. f)
    if b ~= -1 then
      bufs[b] = true
    end
  end
  for buf in pairs(bufs) do
    if
      not st.preexisting[buf]
      and vim.api.nvim_buf_is_valid(buf)
      and not vim.bo[buf].modified
      and #vim.fn.win_findbuf(buf) == 0
    then
      pcall(vim.api.nvim_buf_delete, buf, {})
    end
  end
end

function M.finish()
  local st = _G.__claude_review
  if not st then
    return
  end
  vim.ui.input({ prompt = "Overall comment (empty for none): " }, function(general)
    if general == nil then
      return -- <Esc>: keep reviewing
    end
    harvest_inline(st)
    M.close("done", general)
  end)
end

--- Entry point, called over RPC with the path to the payload JSON.
function M.open(payload_file)
  local ok, err = pcall(function()
    local f = assert(io.open(payload_file, "r"))
    local p = vim.json.decode(f:read("*a"))
    f:close()

    if _G.__claude_review then
      M.close("superseded")
    end

    local preexisting = {}
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[b].buflisted then
        preexisting[b] = true
      end
    end

    vim.cmd("tabnew")
    -- tabnew's empty buffer is replaced by the baseline scratch; wipe it then.
    vim.bo.bufhidden = "wipe"
    local st = {
      root = p.root,
      base = p.base,
      proposed = p.proposed,
      response = p.response,
      title = p.title or "",
      files = p.files,
      idx = 1,
      comments = {},
      base_bufs = {},
      touched = {},
      preexisting = preexisting,
      tab = vim.api.nvim_get_current_tabpage(),
    }
    _G.__claude_review = st

    st.base_win = vim.api.nvim_get_current_win()
    vim.cmd("rightbelow vsplit " .. vim.fn.fnameescape(st.root .. "/" .. st.files[1]))
    st.file_win = vim.api.nvim_get_current_win()

    local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = group,
      callback = function(ev)
        local cur = _G.__claude_review
        if not cur or vim.api.nvim_get_current_win() ~= cur.file_win then
          return
        end
        local idx = file_index(cur, vim.api.nvim_buf_get_name(ev.buf))
        if idx and idx ~= cur.idx then
          vim.schedule(function()
            -- Skip when the review closed or goto_file already paired it.
            if _G.__claude_review == cur and vim.api.nvim_win_is_valid(cur.file_win) and cur.idx ~= idx then
              pair(cur, idx)
            end
          end)
        end
      end,
    })
    vim.api.nvim_create_autocmd("TabClosed", {
      group = group,
      callback = function()
        local cur = _G.__claude_review
        if cur and not vim.api.nvim_tabpage_is_valid(cur.tab) then
          vim.schedule(function() M.close("cancelled") end)
        end
      end,
    })

    pair(st, 1)

    vim.fn.setloclist(st.file_win, {}, " ", {
      title = "Claude review",
      items = hunk_items(st),
      quickfixtextfunc = "v:lua._claude_review_qftf",
    })
    -- The list belongs to the file window (so <CR> jumps there) but sits
    -- under the base window, keeping the file side full height.
    vim.cmd("lopen")
    local list_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_config(list_win, { split = "below", win = st.base_win })
    vim.api.nvim_win_set_height(list_win, 8)
    vim.wo[list_win].winfixheight = true
    vim.wo[list_win].wrap = false
    map_review_keys(st, vim.api.nvim_win_get_buf(list_win))
    vim.cmd("wincmd =")
    vim.api.nvim_set_current_win(st.file_win)
    vim.cmd("normal! gg]c")
  end)
  return ok and "ok" or tostring(err)
end

return M
