local Comments = require("pi-review.comments")
local M = { actions = {}, contexts = {} }
local target

local function read_state(ctx)
  local file = assert(io.open(ctx.file, "rb"))
  local state = vim.json.decode(file:read("*a"))
  file:close()
  assert(state.version == 2 and state.root == ctx.root, "Invalid/legacy task state; migrate with pi-task first")
  return state
end
M.state = read_state

local function safe_env()
  local env = {}
  for key, value in pairs(vim.fn.environ()) do
    if
      key == "PATH"
      or key == "HOME"
      or key == "USER"
      or key == "LANG"
      or key == "TMPDIR"
      or key:match("^LC_")
      or key:match("^XDG_")
    then
      env[key] = value
    end
  end
  return env
end

function M.command(ctx, operation, ...)
  local args = { "pi-task", "review-internal", operation, ctx.root, ctx.file }
  vim.list_extend(args, { ... })
  local result = vim.system(args, { text = true, env = ctx.env or safe_env(), clear_env = true }):wait()
  assert(result.code == 0, vim.trim(result.stderr or "Task state update failed"))
  return result.stdout ~= "" and vim.json.decode(result.stdout) or read_state(ctx)
end

function M.text_command(ctx, operation, args, text)
  local path = vim.fn.tempname()
  local file = assert(io.open(path, "wb"))
  assert(vim.fn.setfperm(path, "rw-------") == 1, "Cannot protect feedback temporary file")
  assert(file:write(text))
  assert(file:close())
  local call = vim.list_extend(vim.deepcopy(args), { path })
  local ok, result = pcall(M.command, ctx, operation, unpack(call))
  os.remove(path)
  if not ok then
    error(result)
  end
  return result
end

function M.configure(ctx)
  local immutable = vim.env.PI_TASK_ROOT and assert(vim.uv.fs_realpath(vim.env.PI_TASK_ROOT), "Task root unavailable")
  assert(not immutable or immutable == ctx.root, "Cannot route feedback to another task's Pi")
  read_state(ctx)
  target = ctx
end

local function task_context()
  local current = M.contexts[vim.api.nvim_get_current_tabpage()]
  if current then
    return current
  end
  if target then
    return target
  end
  if not vim.env.PI_TASK_ROOT then
    vim.notify("Use the task editor, or open /review from its Pi session", vim.log.levels.WARN)
    return
  end
  local root = assert(vim.uv.fs_realpath(vim.env.PI_TASK_ROOT), "Task root unavailable")
  local common = vim
    .system({ "git", "-C", root, "rev-parse", "--path-format=absolute", "--git-common-dir" }, { text = true })
    :wait()
  assert(common.code == 0, common.stderr)
  M.configure({
    root = root,
    file = vim.env.PI_TASK_REVIEW_STATE
      or vim.trim(common.stdout) .. "/pi-task/reviews/" .. vim.fn.sha256(root):sub(1, 12) .. ".json",
  })
  return target
end

local function content(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end
local function show(buf)
  vim.cmd("belowright split")
  vim.api.nvim_win_set_buf(0, buf)
end
local function new_buffer(ctx, kind, text)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(
    buf,
    "pi-review://" .. vim.fn.sha256(ctx.file):sub(1, 12) .. "/" .. kind .. "/" .. buf .. ".md"
  )
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.b[buf].pi_review = { file = ctx.file, kind = kind }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
  vim.bo[buf].modified = false
  return buf
end

function M.draft(ctx)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local meta = vim.b[buf].pi_review
    if meta and meta.file == ctx.file and meta.kind == "draft" then
      if not vim.bo[buf].modified then
        local state = read_state(ctx)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(state.draft, "\n", { plain = true }))
        vim.b[buf].pi_review_version = state.draftVersion
        vim.bo[buf].modified = false
      end
      show(buf)
      return buf
    end
  end
  local state = read_state(ctx)
  local buf = new_buffer(ctx, "draft", state.draft)
  vim.b[buf].pi_review_version = state.draftVersion
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local saved = M.text_command(ctx, "draft", { tostring(vim.b[buf].pi_review_version) }, content(buf))
      vim.b[buf].pi_review_version = saved.draftVersion
      vim.bo[buf].modified = false
    end,
  })
  show(buf)
  return buf
end

local function close_composer(buf)
  if vim.api.nvim_get_current_buf() == buf then
    vim.cmd("stopinsert")
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.api.nvim_buf_delete(buf, { force = true })
end

function M.compose(ctx, first, last, source, note, on_done)
  local location = note and note.location or Comments.context(ctx, first, last, source)
  local buf = new_buffer(ctx, "compose", note and note.text or "")
  vim.bo[buf].modified = true
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      if note then
        Comments.edit(note, content(buf))
      else
        Comments.add(ctx, location, content(buf))
      end
      close_composer(buf)
      if on_done then
        on_done()
      end
      vim.notify("Comment kept in Neovim memory; Submit sends it, quitting loses it")
    end,
  })
  local width = math.min(80, math.max(1, vim.o.columns - 4))
  local height = math.min(8, math.max(1, vim.o.lines - 4))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
    title = " Comment: " .. Comments.label({ location = location }) .. " ",
    footer = " Ctrl-S: keep in memory · Ctrl-Q: discard "
      .. (location.path and not note and "· Ctrl-T: scope " or ""),
  })
  vim.wo.wrap = true
  if location.path and not note then
    local selected = location
    vim.keymap.set({ "n", "i" }, "<C-t>", function()
      location = location.path and {} or selected
      vim.api.nvim_win_set_config(win, { title = " Comment: " .. Comments.label({ location = location }) .. " " })
    end, { buffer = buf, desc = "Toggle source / task-wide comment" })
  end
  vim.keymap.set({ "n", "i" }, "<C-s>", "<Cmd>write<CR>", { buffer = buf, desc = "Add comment to feedback" })
  vim.keymap.set({ "n", "i" }, "<C-q>", function()
    close_composer(buf)
  end, { buffer = buf, desc = "Discard comment" })
  vim.cmd("startinsert")
  return buf
end

function M.pending(ctx)
  return #Comments.list(ctx)
end

function M.stage(ctx)
  local items = Comments.list(ctx)
  if #items == 0 then
    return
  end
  -- Only Submit crosses the durability boundary. Failed submissions remain in the saved draft.
  M.text_command(ctx, "append", {}, Comments.format(items))
  for _, note in ipairs(items) do
    Comments.delete(note)
  end
end

function M.comments(ctx)
  return Comments.open_list(ctx, function(note, refresh)
    M.compose(ctx, nil, nil, nil, note, refresh)
  end)
end

function M.flush(ctx)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local meta = vim.b[buf].pi_review
    if meta and meta.file == ctx.file and vim.bo[buf].modified then
      assert(meta.kind == "draft", "Save/add or explicitly discard open composer before finishing")
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("write")
      end)
    end
  end
end

function M.history(ctx)
  local lines = { "# Review submission history", "" }
  for _, item in ipairs(read_state(ctx).submissions) do
    vim.list_extend(lines, {
      "## " .. item.id .. " — " .. (item.delivered and "delivered" or "unconfirmed; /review-feedback retries"),
      "",
      item.text,
      "",
    })
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(table.concat(lines, "\n"), "\n", { plain = true }))
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  show(buf)
end

local function review_action(ctx, action)
  if not M.actions[ctx.file] then
    vim.notify("Open /review in coordinating Pi first", vim.log.levels.WARN)
    return
  end
  return M.actions[ctx.file](action)
end

function M.setup()
  Comments.setup()
  local function command(name, callback, opts)
    opts = opts or {}
    opts.force = true
    vim.api.nvim_create_user_command(name, function(args)
      local ctx = task_context()
      if ctx then
        callback(ctx, args, vim.api.nvim_get_current_buf())
      end
    end, opts)
  end
  command("PiReviewNote", function(ctx, args, source)
    M.compose(ctx, args.line1, args.line2, source)
  end, { range = true })
  command("PiReviewComments", M.comments)
  command("PiReviewDraft", M.draft)
  command("PiReviewFinish", function(ctx)
    review_action(ctx, "accept")
  end)
  command("PiReviewSubmit", function(ctx)
    review_action(ctx, "changes")
  end)
  command("PiReview", function(ctx)
    vim.ui.select(
      { "Comments (memory only)", "Saved draft", "Delivery history", "Repositories / coverage", "Recovery help" },
      {
        prompt = "Review tools:",
      },
      function(choice)
        if choice == "Comments (memory only)" then
          M.comments(ctx)
        elseif choice == "Saved draft" then
          M.draft(ctx)
        elseif choice == "Delivery history" then
          M.history(ctx)
        elseif choice == "Repositories / coverage" then
          review_action(ctx, "repositories")
        elseif choice == "Recovery help" then
          vim.notify(
            "In task Pi: /review-feedback retries unconfirmed delivery (may duplicate).\n"
              .. "/review-coordinator explicitly transfers coordination to that session; does not resume work."
          )
        end
      end
    )
  end)
end
return M
