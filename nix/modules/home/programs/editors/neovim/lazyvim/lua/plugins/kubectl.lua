return {
  "ramilito/kubectl.nvim",
  -- use a release tag to download pre-built binaries
  version = "2.*",
  -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  -- build = 'cargo build --release',
  dependencies = "saghen/blink.download",
  config = function()
    require("kubectl").setup({})
  end,
}
