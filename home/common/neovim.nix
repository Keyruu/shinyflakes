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
  ];

  home.file.".config/nvim/init.lua".source = ./lazyvim/init.lua;
  home.file.".config/nvim/stylua.toml".source = ./lazyvim/stylua.toml;
  home.file.".config/nvim/lua".source = ./lazyvim/lua;
}
