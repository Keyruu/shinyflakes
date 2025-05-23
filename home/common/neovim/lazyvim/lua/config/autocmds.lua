-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local ccFidgetGroup = vim.api.nvim_create_augroup("CodeCompanionFidgetHooks", {})

vim.api.nvim_create_autocmd({ "User" }, {
  pattern = "CodeCompanionRequest*",
  group = ccFidgetGroup,
  callback = function(request)
    local handle = nil
    if request.match == "CodeCompanionRequestStarted" then
      handle = require("fidget.progress").handle.create({
        title = " Requesting assistance",
        lsp_client = {
          name = "CodeCompanion",
        },
      })
    elseif request.match == "CodeCompanionRequestFinished" then
      if handle then
        handle:finish()
      end
    end
  end,
})

vim.api.nvim_create_autocmd({ "User" }, {
  pattern = "CodeCompanionAgent*",
  group = ccFidgetGroup,
  callback = function(request)
    local handle = nil
    if request.match == "CodeCompanionAgentStarted" then
      handle = require("fidget.progress").handle.create({
        title = "󰵰 Started agent",
        lsp_client = {
          name = "CodeCompanion",
        },
      })
    elseif request.match == "CodeCompanionAgentFinished" then
      if handle then
        handle:finish()
      end
    end
  end,
})

vim.api.nvim_create_autocmd({ "User" }, {
  pattern = "CodeCompanionTool*",
  group = ccFidgetGroup,
  callback = function(request)
    local handle = nil
    if request.match == "CodeCompanionToolStarted" then
      handle = require("fidget.progress").handle.create({
        title = string.format(" Started tool - %s", request.data.tool),
        lsp_client = {
          name = "CodeCompanion",
        },
      })
    elseif request.match == "CodeCompanionToolFinished" then
      if handle then
        handle:finish()
      end
    end
  end,
})

-- vim.api.nvim_create_autocmd("CursorHold", {
--   callback = function()
--     vim.diagnostic.open_float(nil, { focusable = true, source = "if_many" })
--   end,
-- })
