require("diffview").setup({ clean_up_buffers = false, auto_close_on_empty = false })
require("pi-guardian.batch-notes").setup()
for key, action in pairs({
  n = { "PiReviewNote", "Comment at cursor" },
  d = { "PiReviewDraft", "Review feedback" },
  c = { "PiReviewSubmit", "Request changes" },
  f = { "PiReviewFinish", "Finish review (no model turn)" },
}) do
  vim.keymap.set("n", "<leader>r" .. key, "<Cmd>" .. action[1] .. "<CR>", { desc = action[2] })
end
vim.keymap.set("x", "<leader>rn", ":PiReviewNote<CR>", { desc = "Comment on selected source" })
