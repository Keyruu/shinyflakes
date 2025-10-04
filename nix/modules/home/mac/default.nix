{
  ...
}:
{
  imports = [
    ../common/common.nix
    ../common/neovim
    ../common/intellij.nix
    ../common/kubie.nix
    ../common/shell
    ../common/programs/kitty.nix
    ../common/programs/zathura.nix
    ../common/programs/helix.nix
    ../common/programs/nh.nix
    ../common/programs/opencode.nix
    ../common/bin.nix
    ../common/ssh.nix
    ./scripts
    ./aerospace.nix
    ./kanata.nix
    ./borders.nix
  ];

  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
