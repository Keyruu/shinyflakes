{
  inputs,
  username,
  ...
}: {
  imports = [
    ../../home/common.nix
    ../../home/neovim.nix
    ../../home/shell
    ../../home/programs
    ../../home/ssh.nix
    ./hyprland.nix
  ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";

    stateVersion = "24.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
