# A standalone neovim for viewing zellij/kitty scrollback: loads baleia.nvim to
# turn raw ANSI escapes into highlights, then locks the buffer read-only.
# Built with nix-wrapper-modules (thin wrapper, no per-plugin option DSL) as a
# trial of that approach vs nvf.
{ inputs, pkgs, ... }:
inputs.nix-wrapper-modules.lib.evalPackage [
  { inherit pkgs; }
  (
    {
      wlib,
      ...
    }:
    {
      imports = [ wlib.wrapperModules.neovim ];

      # Distinct binary + dont_link so this sits in home.packages next to the
      # main nvf nvim without a share/nvim path collision.
      binName = "nvim-scrollback";
      settings.dont_link = true;

      # ./ (this folder) is the isolated nvim config dir — init.lua next to this
      # file is loaded instead of ~/.config/nvim.
      settings.config_directory = ./.;

      # Plugins installed on the packpath so require() resolves in
      # init.lua; no manual runtimepath append. Setup lives in init.lua.
      specs.baleia.data = pkgs.vimPlugins.baleia-nvim;
      specs.kanagawa.data = pkgs.vimPlugins.kanagawa-nvim;

      # wl-copy/wl-paste back the unnamedplus clipboard so yanks from the
      # scrollback land in the system clipboard.
      runtimePkgs = [ pkgs.wl-clipboard ];
    }
  )
]
