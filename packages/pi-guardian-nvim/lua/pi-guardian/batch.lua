local Notes = require("pi-guardian.batch-notes")
local M = {}
local active = {}

function M.open(payload)
  assert(
    type(payload.repositories) == "table" and #payload.repositories > 0,
    "Native Diffview repository payload required"
  )
  assert(type(payload.env) == "table", "Sanitized helper environment required")
  local diffview, lib = require("diffview"), require("diffview.lib")
  if active[payload.id] then
    active[payload.id].close()
  end
  local s = {
    ctx = { root = payload.root, id = payload.id, agent = payload.agent, env = payload.env },
    views = {},
    closed = false,
  }
  Notes.configure(s.ctx)
  Notes.setup()
  local function open_repo(repo)
    assert(not repo.problem, repo.problem)
    diffview.open({ "--adapter=git", "-C=" .. repo.root, repo.base })
    local view = assert(lib.get_current_view(), "Diffview did not open")
    s.views[view.tabpage] = view
    Notes.contexts[view.tabpage] = s.ctx
    view.pi_review_state = s.ctx.id
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
      "Unavailable repositories are not reviewed recursively; inspect gitlink changes separately.",
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
  function s.close()
    if s.closed then
      return
    end
    s.closed = true
    active[payload.id] = nil
    Notes.actions[s.ctx.id] = nil
    if s.group then
      vim.api.nvim_del_augroup_by_id(s.group)
    end
    for tab, view in pairs(s.views) do
      Notes.contexts[tab] = nil
      if vim.api.nvim_tabpage_is_valid(tab) then
        view:close()
      end
    end
  end
  Notes.actions[s.ctx.id] = function(action)
    if action == "repositories" then
      s.repositories()
    else
      s.close()
    end
  end
  active[payload.id] = s
  local ok, err = pcall(open_repo, payload.repositories[1])
  if not ok then
    s.close()
    error(err)
  end
  s.group = vim.api.nvim_create_augroup("PiReview" .. s.root_tab, { clear = true })
  vim.api.nvim_create_autocmd("TabClosed", {
    group = s.group,
    callback = function()
      vim.schedule(function()
        if not s.closed and not vim.api.nvim_tabpage_is_valid(s.root_tab) then
          s.close()
        end
      end)
    end,
  })
  for _, repo in ipairs(payload.repositories) do
    if repo.problem or #repo.untracked > 0 or #repo.gitlinks > 0 then
      vim.notify(
        "Review has untracked files/submodules; use :PiReview → Repositories / coverage. No files staged automatically.",
        vim.log.levels.WARN
      )
      break
    end
  end
  return true
end
return M
