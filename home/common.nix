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
    neovim
    git
    gcc
    zig

    # gui apps
    gimp

    # cli apps
    glow # render markdown on the cli

    # utils
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
