return {
  "augmentcode/augment.vim",
  enabled = function()
    local cwd = vim.loop.cwd()
    local file = cwd .. "/.augmentignore"
    local enabled = vim.loop.fs_stat(file) ~= nil
    return enabled
  end,
  config = function()
    local cwd = vim.loop.cwd()
    vim.g.augment_workspace_folders = { cwd }
    -- key binds
  end,
}
