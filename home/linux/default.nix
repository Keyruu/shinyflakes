{
  inputs,
  username,
  pkgs,
  ...
}: {
  imports = [
    ../common/common.nix
    ../common/neovim
    ../common/shell
    ../common/ssh.nix

    ./hypr
    ./wofi.nix
    ./clipman.nix
    ./clipse.nix
    ./discord.nix
    ./themes/nixy.nix
    ./tailscale.nix
    ./dunst.nix
    ./scripts
    ./programs
    ./gaming.nix
  ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";

    stateVersion = "24.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  services.playerctld.enable = true;

  home.packages = with pkgs; [ 
    jq
    yq
    awscli2
    gh # github cli
    kubernetes-helm
    kubectx
    kubectl
    devspace
    uv
    pipx

    squeekboard
    nwg-drawer
    pavucontrol
    rustc
    cargo
    clang
    notion-app-enhanced
    lsof
    hyprpaper
    xournalpp
    calibre
    localsend
    element-desktop
    chromium
    firefox
    railway-travel
    inputs.iio-hyprland.packages.${system}.default
    inputs.zen-browser.packages."${system}".default
  ];
}
