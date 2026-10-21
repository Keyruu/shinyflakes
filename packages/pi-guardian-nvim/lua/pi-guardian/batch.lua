local Notes = require("pi-guardian.batch-notes")
local M = {}
local active = {}

function M.decide(response_file, decision)
  return active[response_file] and active[response_file].finish(decision) or false
end
function M.close(response_file)
  return M.decide(response_file, "pause")
end

function M.open(payload)
  assert(
    type(payload.repositories) == "table" and #payload.repositories > 0,
    "Native Diffview repository payload required"
  )
  assert(type(payload.env) == "table", "Sanitized helper environment required")
  local diffview, lib = require("diffview"), require("diffview.lib")
  for _, review in pairs(active) do
    if review.ctx.file == payload.state_file then
      review.finish("pause")
    end
  end
  local s = {
    ctx = { root = payload.root, file = payload.state_file, env = payload.env },
    views = {},
    closed = false,
  }
  Notes.configure(s.ctx)
  Notes.setup()
  assert(Notes.state(s.ctx).pending.id == payload.id, "Stale review request")

  local function open_repo(repo)
    assert(not repo.problem, repo.problem)
    diffview.open({ "--adapter=git", "-C=" .. repo.root, repo.base })
    local view = assert(lib.get_current_view(), "Diffview did not open")
    s.views[view.tabpage] = view
    s.root_tab = s.root_tab or view.tabpage
  end
  local function report()
    local lines = {
      "# Whole-task Git coverage",
      "",
      "Parent Diffview hides submodules. Use :PiReview → Repositories / coverage for each repository.",
      "",
    }
    for _, repo in ipairs(payload.repositories) do
      vim.list_extend(lines, { "## " .. vim.json.encode(repo.path), "Base: " .. repo.base, "" })
      if repo.problem then
        table.insert(lines, "UNAVAILABLE: " .. repo.problem)
      end
      for _, path in ipairs(repo.untracked) do
        table.insert(lines, "UNTRACKED (not displayed): " .. vim.json.encode(path))
      end
      for _, link in ipairs(repo.gitlinks) do
        table.insert(
          lines,
          "Gitlink "
            .. vim.json.encode(link.path)
            .. ": base="
            .. (link.before or "absent")
            .. "; index="
            .. (link.index or "absent")
            .. "; worktree="
            .. (link.worktree or "unavailable")
        )
      end
      table.insert(lines, "")
    end
    vim.list_extend(lines, {
      "Register new files explicitly with git add -N -- <path>, then refresh Diffview.",
      "After submodule/index topology changes, close and reopen /review to refresh this manifest.",
      "Unavailable repositories require explicit acknowledgement before finishing in Pi; no recursive coverage is implied.",
    })
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false
    vim.cmd("belowright split")
    vim.api.nvim_win_set_buf(0, buf)
  end
  function s.repositories()
    local items = { { path = "Coverage report" } }
    vim.list_extend(items, payload.repositories)
    vim.ui.select(items, {
      prompt = "Task repositories:",
      format_item = function(item)
        return item.path .. (item.problem and " (unavailable)" or "")
      end,
    }, function(repo)
      if not repo then
        return
      end
      if not repo.root or repo.problem then
        report()
      else
        open_repo(repo)
      end
    end)
  end
  function s.finish(decision)
    if s.closed then
      return false
    end
    assert(decision == "accept" or decision == "changes" or decision == "pause", "Unknown review decision")
    if decision ~= "pause" then
      local ok, err = pcall(function()
        local state = Notes.state(s.ctx)
        assert(state.pending and state.pending.id == payload.id, "Stale review")
        Notes.flush(s.ctx)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local path = vim.api.nvim_buf_get_name(buf)
          assert(
            not (path:sub(1, #payload.root + 1) == payload.root .. "/" and vim.bo[buf].modified),
            "Save source buffers before finishing"
          )
        end
        for tab, view in pairs(s.views) do
          assert(
            vim.api.nvim_tabpage_is_valid(tab) and view.ready and not view.is_loading,
            "Wait for Diffview to finish loading"
          )
        end
      end)
      if not ok then
        vim.notify(tostring(err), vim.log.levels.WARN)
        return false
      end
      if
        decision == "accept"
        and Notes.state(s.ctx).draft:find("%S")
        and vim.fn.confirm(
            "Saved feedback will NOT be sent. Use Request changes to send it; Finish keeps it for later.",
            "&Finish without sending\n&Cancel",
            2
          )
          ~= 1
      then
        return false
      end
    end
    local file = assert(io.open(payload.response_file .. ".tmp", "wb"))
    assert(file:write(vim.json.encode({ decision = decision })))
    assert(file:close())
    assert(os.rename(payload.response_file .. ".tmp", payload.response_file))
    s.closed = true
    active[payload.response_file] = nil
    Notes.actions[s.ctx.file] = nil
    if s.group then
      vim.api.nvim_del_augroup_by_id(s.group)
    end
    for tab, view in pairs(s.views) do
      if vim.api.nvim_tabpage_is_valid(tab) then
        view:close()
      end
    end
    return true
  end
  Notes.actions[s.ctx.file] = function(action)
    if action == "repositories" then
      s.repositories()
    else
      s.finish(action)
    end
  end
  active[payload.response_file] = s
  local ok, err = pcall(open_repo, payload.repositories[1])
  if not ok then
    active[payload.response_file] = nil
    Notes.actions[s.ctx.file] = nil
    error(err)
  end
  s.group = vim.api.nvim_create_augroup("PiReview" .. s.root_tab, { clear = true })
  vim.api.nvim_create_autocmd("TabClosed", {
    group = s.group,
    callback = function()
      vim.schedule(function()
        if not s.closed and not vim.api.nvim_tabpage_is_valid(s.root_tab) then
          s.finish("pause")
        end
      end)
    end,
  })
  for _, repo in ipairs(payload.repositories) do
    if repo.problem or #repo.untracked > 0 or #repo.gitlinks > 0 then
      vim.notify(
        "Whole-task review has untracked files/submodules; use :PiReview → Repositories / coverage. No files staged automatically.",
        vim.log.levels.WARN
      )
      break
    end
  end
  return true
end

function M.from_file(path)
  local file = assert(io.open(path, "rb"))
  local payload = vim.json.decode(file:read("*a"))
  file:close()
  local result = M.open(payload)
  os.remove(path)
  return result
end
return M
