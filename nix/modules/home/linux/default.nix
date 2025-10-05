{
  pkgs,
  perSystem,
  ...
}:
{
  imports = [
    ../common/common.nix
    ../common/neovim
    ../common/shell
    ../common/ssh.nix
    ../common/nix-index-database.nix
    ../common/programs/nh.nix

    ./wm
    # ./tofi.nix
    ./clipse.nix
    ./tailscale.nix
    ./dunst.nix
    ./scripts
    ./programs
    ./gaming.nix
    ./workstyle.nix
    ./mpv.nix
  ];

  home.stateVersion = "24.11";

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
    xournalpp
    calibre
    localsend
    element-desktop
    chromium
    firefox
    railway-travel
    wtype
    wireguard-ui
    wireguard-tools
    discord
    vesktop
    slack
    signal-desktop
    perSystem.zen-browser.default
    # inputs.sirberus.packages."${system}".default
  ];
}
