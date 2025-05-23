{
  pkgs,
  username,
  lib,
  ...
}: 
let
  blinkCmpPatched = pkgs.vimPlugins.blink-cmp.overrideAttrs (oldAttrs: {
    postFixup = (oldAttrs.postFixup or "") + ''
      rm -rf $out/LICENSE
      rm -rf $out/README.md
      rm -rf $out/.gitignore
      rm -rf $out/.github
      rm -rf $out/doc
      rm -rf $out/.stylua.toml
    '';
  });
in
{
  home.packages = with pkgs; [
    neovim
    alejandra
    nixd
    gopls
    rust-analyzer
    typescript-language-server
    nodePackages.typescript
    bash-language-server
    tailwindcss-language-server
    nodePackages.vscode-json-languageserver
    helm-ls
    intelephense
    terraform-ls
    yaml-language-server
    astro-language-server
    blinkCmpPatched
    vue-language-server
    svelte-language-server
    lua-language-server
    vimPlugins.nvim-treesitter.withAllGrammars
    markdownlint-cli2
  ];

  home.file.".config/nvim/init.lua".text = /* lua */ ''
    require("config.lazy")
    -- require("core.options") -- Example from LazyVim's structure

    -- Your Neovim init.lua content goes here
    -- You can include the LSP setup with the dynamic tsdk path
    local lspconfig = require('lspconfig')
    local tsdk_path = "${pkgs.nodePackages.typescript}/lib/node_modules/typescript/lib/";

    lspconfig.astro.setup({
      init_options = {
        typescript = {
          tsdk = tsdk_path,
        }
      }
    })
    -- lspconfig.ts_ls.setup({
    --   settings = {
    --     typescript = {
    --       tsdk = tsdk_path,
    --     },
    --     javascript = {
    --       tsdk = tsdk_path,
    --     },
    --   },
    --   root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", ".git"),
    -- })
  '';
  # home.file.".config/nvim/init.lua".source = ./lazyvim/init.lua;
  home.file.".config/nvim/stylua.toml".source = ./lazyvim/stylua.toml;
  home.file.".config/nvim/lua".source = ./lazyvim/lua;
}
