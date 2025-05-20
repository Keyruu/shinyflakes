return {
  "milanglacier/minuet-ai.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "Saghen/blink.cmp",
  },
  opts = {
    provider = "gemini",
    provider_options = {
      gemini = {
        api_key = "GEMINI_API_KEY",
      },
    },
  },
}
