{
  inputs,
  username,
  pkgs,
  ...
}: {
  imports = [
    ../common/common.nix
    ../common/neovim.nix
    ../common/shell
    ../common/ssh.nix

    ./hypr
    ./wofi.nix
    ./clipman.nix
    ./clipse.nix
    ./discord.nix
    ./themes/nixy.nix
    ./spicetify.nix
    ./tailscale.nix
    ./scripts
    ./programs
  ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";

    stateVersion = "24.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [ 
    squeekboard
    nwg-drawer
    pavucontrol
    inputs.iio-hyprland.packages.${system}.default
    inputs.zen-browser.packages."${system}".default
    inputs.hyprswitch.packages."${system}".default
  ];
}
