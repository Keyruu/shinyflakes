require("diffview").setup({ clean_up_buffers = false, auto_close_on_empty = false })
require("pi-guardian.batch-notes").setup()
for key, action in pairs({
  n = { "PiReviewNote", "Comment at cursor" },
  l = { "PiReviewComments", "List pending comments" },
  c = { "PiReviewSend", "Paste annotations into Pi (no Enter)" },
  f = { "PiReviewFinish", "Close review (keep annotations)" },
}) do
  vim.keymap.set("n", "<leader>r" .. key, "<Cmd>" .. action[1] .. "<CR>", { desc = action[2] })
end
vim.keymap.set("x", "<leader>rn", ":PiReviewNote<CR>", { desc = "Comment on selected source" })

-- Review worktree changes; inside an agent-task, against the task's fixed base
-- so commits the agent already made show up too.
local function review()
  local base = ""
  local state = vim.env.PI_TASK_REVIEW_STATE
  if state and vim.uv.fs_stat(state) then
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(state), "\n"))
    if ok and type(data) == "table" and type(data.base) == "string" then base = " " .. data.base end
  end
  vim.cmd("DiffviewOpen" .. base)
end
vim.api.nvim_create_user_command("Review", review, { desc = "Review worktree changes in Diffview" })
vim.keymap.set("n", "<leader>rr", review, { desc = "Review worktree changes" })
vim.keymap.set("n", "<leader>rq", "<Cmd>DiffviewClose<CR>", { desc = "Close Diffview" })
