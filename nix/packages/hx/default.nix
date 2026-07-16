{
  inputs,
  pkgs,
  ...
}:
inputs.nix-wrapper-modules.lib.evalPackage [
  { inherit pkgs; }
  (
    {
      wlib,
      ...
    }:
    {
      imports = [ wlib.wrapperModules.helix ];

      config = {
        # package = pkgs.evil-helix;

        runtimePkgs = with pkgs; [
          # LSPs
          nixd
          nil
          gopls
          rust-analyzer
          typescript-language-server
          typescript
          bash-language-server
          tailwindcss-language-server
          vscode-langservers-extracted
          helm-ls
          terraform-ls
          yaml-language-server
          astro-language-server
          svelte-language-server
          svelte-check
          lua-language-server
          marksman
          # formatters (conform / format-on-save)
          alejandra
          nixfmt
          stylua
          prettier
          markdownlint-cli2
        ];

        themes = (import ./themes.nix);
        settings = (import ./settings.nix);
        languages = (import ./languages.nix);
      };
    }
  )
]
