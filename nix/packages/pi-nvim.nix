{
  pkgs,
  ...
}:
pkgs.vimUtils.buildVimPlugin {
  name = "pi-nvim";
  src = pkgs.fetchFromGitHub {
    owner = "alex35mil";
    repo = "pi.nvim";
    rev = "f2219f0ce79e512b81175d3940e306a49555bca3";
    hash = "sha256-X+aW4G+jYKX1T/XPNlDMgRj0fxRQtoTzo/PuZ+z9zLI=";
  };
}
