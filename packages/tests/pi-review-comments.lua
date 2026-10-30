vim.opt.rtp:prepend(arg[1] .. "/packages/pi-guardian-nvim")
local Comments = require("pi-review.comments")
local Notes = require("pi-guardian.batch-notes")
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
vim.env.PI_TASK_ROOT = nil
local ctx = {
  root = dir,
  id = "pi-session",
  env = {},
  agent = {
    pid = vim.fn.getpid(),
    sessionId = "pi-session",
    session = "test",
    pane = "7",
    statusFile = dir .. "/herd.json",
  },
}
local legacy_file = dir .. "/review.json"
local identity =
  { pid = ctx.agent.pid, sessionId = "pi-session", zellijSession = "test", zellijPaneId = "7", status = "idle" }
local function status(value)
  vim.fn.writefile({ vim.json.encode(value or identity) }, ctx.agent.statusFile)
end
status()
local state = { version = 2, root = dir, draft = "legacy draft", draftVersion = 3, submissions = {} }
vim.fn.writefile({ vim.json.encode(state) }, legacy_file)
Notes.configure(ctx)
Notes.setup()
local count, sequence = 0, 0
local function clear()
  for _, note in ipairs(Comments.list()) do
    Comments.delete(note)
  end
end
local function source(lines)
  sequence = sequence + 1
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, dir .. "/source-" .. sequence .. ".lua")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or { "first", "selected", "last" })
  vim.bo[buf].modified = false
  vim.api.nvim_set_current_buf(buf)
  return buf
end
local function test(name, fn)
  clear()
  fn()
  count = count + 1
  print("PASS " .. name)
end
local function key(buf, lhs)
  local callback
  vim.api.nvim_buf_call(buf, function()
    callback = vim.fn.maparg(lhs, "n", false, true).callback
  end)
  assert(type(callback) == "function", "missing key " .. lhs)
  callback()
end
local ok, err = pcall(function()
  test("composer keeps multiline comments in memory without changing state or source", function()
    local buf = source()
    local before = table.concat(vim.fn.readfile(legacy_file), "\n")
    local composer = Notes.compose(ctx, 2, 2, buf)
    vim.api.nvim_buf_set_lines(composer, 0, -1, false, { "fix this", "keep the context" })
    vim.cmd("write")
    assert(not vim.api.nvim_buf_is_valid(composer))
    assert(Notes.pending(ctx) == 1)
    assert(Comments.list(ctx)[1].text == "fix this\nkeep the context")
    assert(table.concat(vim.fn.readfile(legacy_file), "\n") == before)
    assert(vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1] == "selected")
    assert(not vim.bo[buf].modified)
  end)

  test("range tracks inserted lines without disturbing diff alignment", function()
    local buf = source()
    local note = Comments.add(ctx, Comments.context(ctx, 2, 2, buf), "move with code")
    local ns = vim.api.nvim_get_namespaces()["pi-review-comments"]
    local before = vim.api.nvim_buf_get_extmark_by_id(buf, ns, note.mark, { details = true })
    assert(before[3].virt_text_pos == "eol" and before[3].virt_lines == nil)
    vim.api.nvim_buf_del_extmark(buf, ns, note.mark)
    Comments.decorate(note)
    assert(#vim.api.nvim_buf_get_extmark_by_id(buf, ns, note.mark, {}) > 0, "recreate lost display marks")
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "inserted" })
    Comments.jump(note)
    assert(vim.api.nvim_win_get_cursor(0)[1] == 3)
    assert(Comments.format({ note }):find("at comment creation", 1, true))
    assert(note.location.excerpt == "selected")
    local id = note.mark
    Comments.edit(note, "updated")
    assert(note.mark == id)
    local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, id, { details = true })
    assert(mark[1] == 2 and mark[3].virt_text[1][1]:find("updated", 1, true))
    Comments.delete(note)
    assert(#vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) == 0)
  end)

  test("deleted source and wiped buffers never delete pending feedback", function()
    local buf = source()
    local note = Comments.add(ctx, Comments.context(ctx, 2, 2, buf), "keep me")
    vim.api.nvim_buf_set_lines(buf, 1, 2, false, {})
    local before = vim.api.nvim_win_get_cursor(0)[1]
    Comments.jump(note)
    assert(vim.api.nvim_win_get_cursor(0)[1] == before)
    vim.api.nvim_buf_delete(buf, { force = true })
    assert(#Comments.list(ctx) == 1)
    assert(Comments.format({ note }):find("selected", 1, true))
    Comments.edit(note, "still editable")
    assert(note.text == "still editable")
  end)

  test("historical submodule context uses the real path and repository, not the buffer URI", function()
    local buf = source()
    vim.api.nvim_buf_set_name(buf, "diffview://historical/child.lua")
    local previous = package.loaded["diffview.lib"]
    package.loaded["diffview.lib"] = {
      get_current_view = function()
        return {
          cur_layout = {
            windows = {
              {
                file = {
                  bufnr = buf,
                  absolute_path = dir .. "/vendor/child.lua",
                  path = "child.lua",
                  adapter = { ctx = { toplevel = dir .. "/vendor" } },
                  rev = { commit = "historical-commit" },
                },
              },
            },
          },
        }
      end,
    }
    local location = Comments.context(ctx, 2, 2, buf)
    package.loaded["diffview.lib"] = previous
    assert(location.path == "vendor/child.lua" and location.diff_path == "child.lua")
    assert(location.repo == dir .. "/vendor" and location.revision == "historical-commit")
    assert(location.excerpt == "selected")
  end)

  test("original excerpts safely quote Markdown and stay isolated per review", function()
    local buf = source({ "````", "original" })
    local note = Comments.add(ctx, Comments.context(ctx, 1, 2, buf), "remark")
    local other = { root = dir, id = "other-session" }
    Comments.add(other, {}, "other review")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "replacement" })
    local text = Comments.format(Comments.list(ctx))
    assert(text:find("`````\n````\noriginal\n`````", 1, true))
    assert(not text:find("replacement", 1, true))
    assert(not text:find("other review", 1, true))
    assert(Comments.list(ctx)[1] == note)
  end)

  test("paste is targeted, multiline and never presses Enter or changes existing drafts", function()
    local original = vim.system
    local calls = {}
    vim.system = function(args, opts)
      assert(args[1] == "zellij" and args[2] == "--session" and args[3] == "test" and args[4] == "action")
      assert(opts.clear_env and opts.env == ctx.env)
      table.insert(calls, args)
      return {
        wait = function()
          return { code = 0, stdout = args[5] == "list-panes" and '[{"id":7,"is_plugin":false,"exited":false}]' or "" }
        end,
      }
    end
    Comments.add(ctx, {}, "--literal\nquote ' \" and $shell")
    Comments.add({ id = "other" }, {}, "not this review")
    local before = table.concat(vim.fn.readfile(legacy_file), "\n")
    Notes.send(ctx)
    vim.system = original
    assert(#calls == 3 and calls[1][5] == "list-panes" and calls[2][5] == "paste" and calls[3][5] == "focus-pane-id")
    assert(calls[2][6] == "--pane-id" and calls[2][7] == "7" and calls[2][8] == "--")
    assert(calls[2][9]:find("--literal\nquote ' \" and $shell", 1, true))
    assert(#Comments.list(ctx) == 0 and #Comments.list({ id = "other" }) == 1)
    assert(table.concat(vim.fn.readfile(legacy_file), "\n") == before)
    assert(not pcall(Notes.send, ctx), "empty sends refuse")
  end)

  test("failed paste keeps comments; focus failure after paste does not duplicate them", function()
    local note = Comments.add(ctx, {}, "keep on failure")
    local original = Notes.command
    Notes.command = function(_, action)
      if action == "list-panes" then
        return '[{"id":7,"is_plugin":false,"exited":false}]'
      end
      error("paste failed")
    end
    assert(not pcall(Notes.send, ctx))
    assert(Comments.list(ctx)[1] == note)
    local pastes = 0
    Notes.command = function(_, action)
      if action == "list-panes" then
        return '[{"id":7,"is_plugin":false,"exited":false}]'
      end
      if action == "paste" then
        pastes = pastes + 1
        return ""
      end
      error("focus failed")
    end
    Notes.send(ctx)
    assert(#Comments.list(ctx) == 0 and pastes == 1)
    assert(not pcall(Notes.send, ctx))
    assert(pastes == 1)
    Notes.command = original
  end)

  test("changed identities, unavailable panes and terminal control characters fail closed", function()
    Comments.add(ctx, {}, "keep me")
    local original = Notes.command
    local panes = '[{"id":7,"is_plugin":false,"exited":false}]'
    Notes.command = function(_, action)
      assert(action == "list-panes", "must never paste to an invalid target")
      return panes
    end
    for _, change in ipairs({
      { sessionId = "other-conversation" },
      { zellijSession = "other-session" },
      { zellijPaneId = "8" },
      { pid = 2147483647 },
      { status = "waiting" },
    }) do
      status(vim.tbl_extend("force", identity, change))
      assert(not pcall(Notes.send, ctx))
      assert(#Comments.list(ctx) == 1)
    end
    status()
    for _, invalid in ipairs({
      "[]",
      '[{"id":7,"is_plugin":true,"exited":false}]',
      '[{"id":7,"is_plugin":false,"exited":true}]',
      '[{"id":7,"is_plugin":false,"exited":false,"is_held":true}]',
    }) do
      panes = invalid
      assert(not pcall(Notes.send, ctx))
    end
    local pid = ctx.agent.pid
    ctx.agent.pid = 2147483647
    status(vim.tbl_extend("force", identity, { pid = ctx.agent.pid }))
    assert(not pcall(Notes.send, ctx), "dead process refuses")
    ctx.agent.pid = pid
    status()
    Comments.edit(Comments.list(ctx)[1], "escape" .. string.char(27) .. "[201~")
    assert(not pcall(Notes.send, ctx))
    assert(#Comments.list(ctx) == 1)
    Notes.command = original
  end)

  test("comment list edits multiline text and deletes without submitting", function()
    local note = Comments.add(ctx, {}, "old text")
    local list = Notes.comments(ctx)
    key(list, "e")
    local composer = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(composer, 0, -1, false, { "new text", "second line" })
    vim.cmd("write")
    assert(note.text == "new text\nsecond line")
    assert(vim.api.nvim_buf_get_lines(list, 0, 1, false)[1]:find("new text", 1, true))
    key(list, "d")
    assert(#Comments.list(ctx) == 0 and not vim.api.nvim_buf_is_valid(list))
  end)

  test("open composers block submit; discard and task-wide toggle stay memory-only", function()
    local buf = source()
    local composer = Notes.compose(ctx, 2, 2, buf)
    assert(not pcall(Notes.flush, ctx))
    key(composer, "<C-t>")
    vim.api.nvim_buf_set_lines(composer, 0, -1, false, { "whole task" })
    vim.cmd("write")
    assert(Comments.list(ctx)[1].location.path == nil)
    composer = Notes.compose(ctx, 1, 1, buf)
    key(composer, "<C-q>")
    assert(#Comments.list(ctx) == 1)
    Notes.flush(ctx)
  end)
end)
clear()
vim.fn.delete(dir, "rf")
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
print(count .. " comment checks passed")
vim.cmd("qa!")
