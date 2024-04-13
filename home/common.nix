{pkgs, ...}: {
  dconf.enable = true;
  nixpkgs.config.allowUnfree = true;

  services = {
    easyeffects.enable = true;
    udiskie.enable = true;
  };

  home.packages = with pkgs; [
    # development
    python3
    rustup
    lua
    nodejs
    actionlint
    gitmoji-cli
    pre-commit
    git
    gcc
    zig
    jetbrains.idea-ultimate
    vscode

    # gui apps
    gimp
    _1password-gui
    obsidian

    # cli apps
    glow # render markdown on the cli

    # utils
    _1password
    neofetch
    yadm
    rsync
    rclone
    pciutils
    usbutils
    ffmpeg-full
    nix-diff
    p7zip
  ];
}
