{
  pkgs,
  ...
}:
pkgs.vimUtils.buildVimPlugin {
  name = "pi-guardian-nvim";
  src = ./pi-guardian-nvim;
}
