{
  inputs,
  pkgs,
  perSystem,
  ...
}:
let
  pkgs-stable = import inputs.nixpkgs-stable { system = pkgs.system; };
in
{
  imports = [
    ../common/common.nix
    ../common/neovim
    ../common/shell
    ../common/ssh.nix
    ../common/nix-index-database.nix
    ../common/programs/nh.nix
    ../common/repos.nix

    ./wm
    # ./tofi.nix
    ./clipse.nix
    ./tailscale.nix
    ./dunst.nix
    ./swaync.nix
    ./scripts
    ./programs
    ./gaming.nix
    ./workstyle.nix
    ./mpv.nix
    ./calendar.nix
  ];

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  services.playerctld.enable = true;

  home.packages = with pkgs; [
    jq
    yq
    gh # github cli
    pkgs-stable.awscli2
    kubernetes-helm
    kubectx
    kubectl
    devspace
    uv
    pipx
    impala
    claude-code

    pavucontrol
    rustc
    cargo
    clang
    notion-app-enhanced
    lsof
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
    rpi-imager
    espflash
    thunderbird
    vlc
    isd
    bluetui
    aichat
    socat
    perSystem.zen-browser.default
    # inputs.sirberus.packages."${system}".default
  ];
}
