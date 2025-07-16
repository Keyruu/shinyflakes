local M = {}

-- State tracking
local watcher_handle = nil
local is_watching = false
local internal_changes = {}
local debounce_timer = nil
local cached_gitignore_patterns = {}
local cached_cwd = nil

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
      else
        -- Open file in new buffer
        vim.cmd.edit(filepath)
        vim.notify(string.format("Opened: %s", vim.fn.fnamemodify(filepath, ":~:.")), vim.log.levels.INFO)
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

      if not filename or not events.change then
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

    if cmd == "opencode-sst" then
      vim.defer_fn(function()
        -- Check if terminal is visible
        local term_visible = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local buf_name = vim.api.nvim_buf_get_name(buf)
          if buf_name:match("opencode%-sst") then
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

