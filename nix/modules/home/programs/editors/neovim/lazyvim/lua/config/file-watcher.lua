local M = {}

-- State tracking
local watcher_handle = nil
local is_watching = false
local internal_changes = {}
local debounce_timer = nil
local cached_gitignore_patterns = {}
local cached_cwd = nil
local open_diffs = {} -- Track open diff buffers by filepath

-- Parse .gitignore file and convert patterns to Lua patterns
local function parse_gitignore(cwd)
  local gitignore_patterns = {}
  local gitignore_path = cwd .. "/.gitignore"

  if vim.fn.filereadable(gitignore_path) == 1 then
    local lines = vim.fn.readfile(gitignore_path)
    for _, line in ipairs(lines) do
      -- Skip empty lines and comments
      line = line:gsub("^%s+", ""):gsub("%s+$", "")
      if line ~= "" and not line:match("^#") then
        -- Convert gitignore pattern to Lua pattern
        local pattern = line
        -- Escape special Lua pattern characters except * and ?
        pattern = pattern:gsub("([%.%+%-%^%$%(%)%[%]%%])", "%%%1")
        -- Convert gitignore wildcards to Lua patterns
        pattern = pattern:gsub("%*", ".*")
        pattern = pattern:gsub("%?", ".")
        -- Handle directory patterns
        if pattern:match("/$") then
          pattern = pattern .. ".*"
        else
          pattern = pattern .. "$"
        end
        table.insert(gitignore_patterns, pattern)
      end
    end
  end

  return gitignore_patterns
end

-- Check if file should be processed
local function should_process_file(filename)
  if not filename then
    return false
  end

  -- Skip directories and hidden files
  if filename:match("/$") or filename:match("^%.") then
    return false
  end

  -- Skip ignored paths (built-in patterns)
  local ignore_patterns = {
    "%.git/",
    "node_modules/",
    "%.cache/",
    "dist/",
    "build/",
    "__pycache__/",
    "%.DS_Store$",
    "%.swp$",
    "%.swo$",
    "%.tmp$",
    "%.log$",
    "%.lock$",
    "%.min%.js$",
    "%.min%.css$",
  }

  -- Add cached gitignore patterns
  for _, pattern in ipairs(cached_gitignore_patterns) do
    table.insert(ignore_patterns, pattern)
  end

  for _, pattern in ipairs(ignore_patterns) do
    if filename:match(pattern) then
      return false
    end
  end

  return true
end

-- Track internal changes to avoid opening files we just saved
local function track_internal_changes()
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = vim.api.nvim_create_augroup("FileWatcherInternal", { clear = true }),
    callback = function(ev)
      if ev.file then
        internal_changes[ev.file] = vim.loop.now()
      end
    end,
  })
end

-- Check if a change was internal (within last 3 seconds)
local function is_internal_change(filepath)
  local last_change = internal_changes[filepath]
  if not last_change then
    return false
  end
  return (vim.loop.now() - last_change) < 3000
end

-- Find the main editor window (not terminal, floating, etc.)
local function find_main_editor_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
    local config = vim.api.nvim_win_get_config(win)

    -- Skip floating windows, terminals, and special buffers
    if config.relative == "" and buftype == "" then
      return win
    end
  end
  return nil
end

-- Create git diff for a file
local function create_git_diff(filepath)
  -- Check if diff is already open for this file
  if open_diffs[filepath] then
    local bufnr = open_diffs[filepath]
    if vim.api.nvim_buf_is_valid(bufnr) then
      return -- Diff already exists
    else
      open_diffs[filepath] = nil -- Clean up invalid buffer reference
    end
  end

  -- Get the current file path relative to git root
  local file = vim.fn.expand("%")
  if file == "" then
    file = vim.fn.fnamemodify(filepath, ":.")
  end

  -- Check if file is in git repository
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if vim.v.shell_error ~= 0 then
    return -- Not in a git repository
  end

  -- Get relative path from git root
  local relative_path = vim.fn.fnamemodify(filepath, ":.")

  -- Get git content
  local git_content = vim.fn.system("git show HEAD:" .. relative_path .. " 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return -- File not in git or other error
  end

  -- Save current window and buffer
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current_win)

  -- Enable diff mode for current buffer
  vim.cmd("diffthis")

  -- Create new window on the left
  vim.cmd("leftabove vnew")
  local git_buf = vim.api.nvim_get_current_buf()

  -- Set buffer name and options
  local git_buf_name = string.format("[Git HEAD] %s", vim.fn.fnamemodify(filepath, ":t"))
  vim.api.nvim_buf_set_name(git_buf, git_buf_name)
  vim.bo[git_buf].buftype = "nofile"
  vim.bo[git_buf].bufhidden = "wipe"
  vim.bo[git_buf].buflisted = false
  vim.bo[git_buf].swapfile = false
  vim.bo[git_buf].modifiable = true

  -- Set git content in buffer
  vim.api.nvim_buf_set_lines(git_buf, 0, -1, false, vim.split(git_content, "\n"))
  vim.bo[git_buf].modifiable = false

  -- Enable diff mode for git buffer
  vim.cmd("diffthis")

  -- Set filetype to match original for syntax highlighting
  local original_filetype = vim.api.nvim_buf_get_option(current_buf, "filetype")
  vim.bo[git_buf].filetype = original_filetype

  -- Track this diff buffer
  open_diffs[filepath] = git_buf

  -- Set up autocmd to clean up when buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = git_buf,
    callback = function()
      open_diffs[filepath] = nil
    end,
    once = true,
  })

  -- Return focus to original window
  vim.api.nvim_set_current_win(current_win)
end

-- Handle file changes with debouncing
local function handle_file_change(filepath)
  -- Clear existing debounce timer
  if debounce_timer then
    debounce_timer:stop()
    debounce_timer:close()
  end

  -- Debounce the file change handling
  debounce_timer = vim.defer_fn(function()
    debounce_timer = nil

    -- Skip internal changes
    if is_internal_change(filepath) then
      return
    end

    -- Skip if file doesn't exist
    if vim.fn.filereadable(filepath) == 0 then
      return
    end

    vim.schedule(function()
      local bufnr = vim.fn.bufnr(filepath)

      if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        -- File is already open, reload it
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("checktime")
        end)
        vim.notify(string.format("Reloaded: %s", vim.fn.fnamemodify(filepath, ":~:.")), vim.log.levels.INFO)
        vim.api.nvim_set_current_buf(bufnr)

        create_git_diff(filepath)
      else
        vim.cmd.edit(filepath)
        vim.notify(string.format("Opened: %s", vim.fn.fnamemodify(filepath, ":~:.")), vim.log.levels.INFO)
        bufnr = vim.fn.bufnr(filepath)
        vim.api.nvim_set_current_buf(bufnr)

        -- Create git diff after a delay to ensure file is fully loaded
        vim.defer_fn(function()
          create_git_diff(filepath)
        end, 500)
      end
    end)
  end, 200)
end

-- Start watching the current working directory
function M.start_watching()
  if is_watching then
    return
  end

  cached_cwd = vim.fn.getcwd()
  cached_gitignore_patterns = parse_gitignore(cached_cwd)
  watcher_handle = vim.loop.new_fs_event()

  if not watcher_handle then
    vim.notify("Failed to create file watcher", vim.log.levels.ERROR)
    return
  end

  local ok, err = pcall(function()
    watcher_handle:start(cached_cwd, { recursive = true }, function(err, filename, events)
      if err then
        vim.notify("File watcher error: " .. tostring(err), vim.log.levels.WARN)
        return
      end

      if not filename then
        return
      end

      -- Handle both file changes and new file creation
      if not (events.change or events.rename) then
        return
      end

      if should_process_file(filename) then
        local full_path = cached_cwd .. "/" .. filename
        handle_file_change(full_path)
      end
    end)
  end)

  if ok then
    is_watching = true
    track_internal_changes()
    vim.notify("File watcher started for: " .. vim.fn.fnamemodify(cached_cwd, ":~"), vim.log.levels.INFO)
  else
    vim.notify("Failed to start file watcher: " .. tostring(err), vim.log.levels.ERROR)
    if watcher_handle and not watcher_handle:is_closing() then
      watcher_handle:close()
    end
    watcher_handle = nil
  end
end

-- Stop the watcher
function M.stop_watching()
  if not is_watching then
    return
  end

  is_watching = false

  -- Stop the main watcher
  if watcher_handle and not watcher_handle:is_closing() then
    watcher_handle:stop()
    watcher_handle:close()
  end
  watcher_handle = nil

  -- Clean up debounce timer
  if debounce_timer then
    debounce_timer:stop()
    debounce_timer:close()
    debounce_timer = nil
  end

  -- Clear state
  internal_changes = {}
  cached_gitignore_patterns = {}
  cached_cwd = nil
  open_diffs = {}

  vim.notify("File watcher stopped", vim.log.levels.INFO)
end

-- Check if watching is active
function M.is_watching()
  return is_watching
end

-- Terminal integration for opencode-sst
function M.setup_terminal_integration()
  local original_toggle = require("snacks.terminal").toggle

  require("snacks.terminal").toggle = function(cmd, opts)
    local result = original_toggle(cmd, opts)

    if cmd == "opencode-sst" or cmd == "opencode" then
      vim.defer_fn(function()
        -- Check if terminal is visible
        local term_visible = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local buf_name = vim.api.nvim_buf_get_name(buf)
          if buf_name:match("opencode%-sst") or buf_name:match("opencode") then
            term_visible = true
            break
          end
        end

        if term_visible then
          M.start_watching()
        else
          M.stop_watching()
        end
      end, 100)
    end

    return result
  end
end

return M
