{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./man.nix
    ./settings.nix
    ./lsp.nix
    ./plugins.nix
    ./keymaps.nix
  ];

  home.packages = with pkgs; [
    alejandra
    nixfmt
    markdownlint-cli2
    nixd
    gopls
    rust-analyzer
    typescript-language-server
    nodePackages.typescript
    bash-language-server
    tailwindcss-language-server
    nodePackages.vscode-json-languageserver
    helm-ls
    terraform-ls
    yaml-language-server
    astro-language-server
    vue-language-server
    svelte-language-server
    lua-language-server
    marksman
  ];

  programs.nvf = {
    enable = true;
    enableManpages = true;
    defaultEditor = true;
  };

  programs.nvf.settings.vim.vimAlias = true;
}
