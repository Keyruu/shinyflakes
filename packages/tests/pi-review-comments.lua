vim.opt.rtp:prepend(arg[1] .. "/packages/pi-guardian-nvim")
local Comments = require("pi-review.comments")
local Notes = require("pi-guardian.batch-notes")
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local ctx = { root = dir, file = dir .. "/review.json" }
local state = { version = 2, root = dir, draft = "legacy draft", draftVersion = 3, submissions = {} }
vim.fn.writefile({ vim.json.encode(state) }, ctx.file)
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
    local before = table.concat(vim.fn.readfile(ctx.file), "\n")
    local composer = Notes.compose(ctx, 2, 2, buf)
    vim.api.nvim_buf_set_lines(composer, 0, -1, false, { "fix this", "keep the context" })
    vim.cmd("write")
    assert(not vim.api.nvim_buf_is_valid(composer))
    assert(Notes.pending(ctx) == 1)
    assert(Comments.list(ctx)[1].text == "fix this\nkeep the context")
    assert(table.concat(vim.fn.readfile(ctx.file), "\n") == before)
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
    local other = { root = dir, file = dir .. "/other.json" }
    Comments.add(other, {}, "other review")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "replacement" })
    local text = Comments.format(Comments.list(ctx))
    assert(text:find("`````\n````\noriginal\n`````", 1, true))
    assert(not text:find("replacement", 1, true))
    assert(not text:find("other review", 1, true))
    assert(Comments.list(ctx)[1] == note)
  end)

  test("submit failure preserves memory; successful handoff appends once to existing draft", function()
    local note = Comments.add(ctx, {}, "ready to send")
    local other = { file = "other-review" }
    Comments.add(other, {}, "not this review")
    local original = Notes.command
    local durable = state.draft
    Notes.command = function()
      error("CLI unavailable")
    end
    assert(not pcall(Notes.stage, ctx))
    assert(Comments.list(ctx)[1] == note)
    Notes.command = function(target, operation, path)
      assert(target == ctx and operation == "append")
      durable = durable .. "\n\n" .. table.concat(vim.fn.readfile(path), "\n")
      return state
    end
    Notes.stage(ctx)
    assert(#Comments.list(ctx) == 0 and #Comments.list(other) == 1)
    assert(durable:find("legacy draft", 1, true) and durable:find("ready to send", 1, true))
    local submitted = durable
    Notes.stage(ctx)
    assert(durable == submitted)
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
