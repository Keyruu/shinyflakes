{
  pkgs,
  username,
  lib,
  ...
}: {
  home.packages = with pkgs; [
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
  ];

  home.file.".config/nvim/init.lua".source = ./lazyvim/init.lua;
  home.file.".config/nvim/stylua.toml".source = ./lazyvim/stylua.toml;
  home.file.".config/nvim/lua".source = ./lazyvim/lua;
}
