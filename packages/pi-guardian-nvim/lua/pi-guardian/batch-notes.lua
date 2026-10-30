local Comments = require("pi-review.comments")
local M = { actions = {}, contexts = {} }
local target

function M.configure(ctx)
  local immutable = vim.env.PI_TASK_ROOT and assert(vim.uv.fs_realpath(vim.env.PI_TASK_ROOT), "Task root unavailable")
  assert(not immutable or immutable == ctx.root, "Cannot route feedback to another task's Pi")
  assert(type(ctx.id) == "string" and type(ctx.agent) == "table", "Open /review from Pi first")
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
  vim.notify("Open /review from the Pi session you want to annotate for", vim.log.levels.WARN)
end

local function content(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end

local function new_buffer(ctx, kind, text)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(
    buf,
    "pi-review://" .. vim.fn.sha256(ctx.id):sub(1, 12) .. "/" .. kind .. "/" .. buf .. ".md"
  )
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.b[buf].pi_review = { id = ctx.id, kind = kind }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
  vim.bo[buf].modified = false
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
      vim.notify("Comment kept in Neovim memory; Send pastes it into Pi; quitting loses it")
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

function M.command(ctx, ...)
  local args = { "zellij", "--session", ctx.agent.session, "action" }
  vim.list_extend(args, { ... })
  local result = vim.system(args, { text = true, env = ctx.env, clear_env = true }):wait(3000)
  assert(result.code == 0, "Zellij failed: " .. (result.stderr or tostring(result.code)))
  return result.stdout
end

local function validate_target(ctx)
  local agent = ctx.agent
  local file = assert(io.open(agent.statusFile, "rb"), "Pi is no longer available; reopen /review")
  local raw = file:read("*a")
  file:close()
  local state = vim.json.decode(raw)
  assert(
    state.pid == agent.pid
      and state.sessionId == agent.sessionId
      and state.zellijSession == agent.session
      and state.zellijPaneId == agent.pane,
    "Pi session changed; reopen /review from the intended conversation"
  )
  assert(vim.uv.kill(agent.pid, 0) == 0, "Pi process exited; comments kept")
  assert(state.status ~= "waiting", "Pi has an open tool dialog; finish it before sending")
  local panes = vim.json.decode(M.command(ctx, "list-panes", "--json", "--all"))
  for _, pane in ipairs(panes) do
    if not pane.is_plugin and tostring(pane.id) == agent.pane and pane.exited == false and not pane.is_held then
      return
    end
  end
  error("Original Pi pane is unavailable; comments kept")
end

function M.send(ctx)
  M.flush(ctx)
  local items = Comments.list(ctx)
  assert(#items > 0, "No annotations to send")
  local text = "Code review comments for "
    .. ctx.root
    .. ":\n\n"
    .. Comments.format(items)
    .. "\n\nPlease address these comments. Re-read source files and preserve existing edits.\n"
  -- Pasted source must not be able to terminate bracketed paste and inject keys.
  assert(
    not text:find("[%z\1-\8\11-\31\127]"),
    "Comments contain terminal control characters; edit them before sending"
  )
  validate_target(ctx)
  M.command(ctx, "paste", "--pane-id", ctx.agent.pane, "--", text)
  for _, note in ipairs(items) do
    Comments.delete(note)
  end
  -- A focus failure must not report paste failure or invite a duplicate send.
  local focused, err = pcall(M.command, ctx, "focus-pane-id", ctx.agent.pane)
  vim.notify(
    focused and "Annotations pasted into Pi. Check the input and press Enter when ready."
      or ("Annotations pasted, but focus failed: " .. tostring(err) .. ". Switch to Pi manually."),
    focused and vim.log.levels.INFO or vim.log.levels.WARN
  )
end

function M.comments(ctx)
  return Comments.open_list(ctx, function(note, refresh)
    M.compose(ctx, nil, nil, nil, note, refresh)
  end)
end

function M.flush(ctx)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local meta = vim.b[buf].pi_review
    assert(
      not (meta and meta.id == ctx.id and vim.bo[buf].modified),
      "Save/add or explicitly discard open composer before sending"
    )
  end
end

local function review_action(ctx, action)
  if not M.actions[ctx.id] then
    vim.notify("Open /review in Pi first", vim.log.levels.WARN)
    return
  end
  return M.actions[ctx.id](action)
end

function M.setup()
  Comments.setup()
  local function command(name, callback, opts)
    opts = opts or {}
    opts.force = true
    vim.api.nvim_create_user_command(name, function(args)
      local ctx = task_context()
      if ctx then
        local ok, err = pcall(callback, ctx, args, vim.api.nvim_get_current_buf())
        if not ok then
          vim.notify(tostring(err), vim.log.levels.WARN)
        end
      end
    end, opts)
  end
  command("PiReviewNote", function(ctx, args, source)
    M.compose(ctx, args.line1, args.line2, source)
  end, { range = true })
  command("PiReviewComments", M.comments)
  command("PiReviewFinish", function(ctx)
    review_action(ctx, "close")
  end)
  command("PiReviewSend", M.send)
  -- Existing bindings must never retain the old auto-submit behavior.
  command("PiReviewSubmit", M.send)
  command("PiReview", function(ctx)
    vim.ui.select({ "Comments (memory only)", "Send to Pi (paste only)", "Repositories / coverage", "Close review" }, {
      prompt = "Review tools:",
    }, function(choice)
      if choice == "Comments (memory only)" then
        M.comments(ctx)
      elseif choice == "Send to Pi (paste only)" then
        vim.cmd("PiReviewSend")
      elseif choice == "Repositories / coverage" then
        review_action(ctx, "repositories")
      elseif choice == "Close review" then
        review_action(ctx, "close")
      end
    end)
  end)
end
return M
