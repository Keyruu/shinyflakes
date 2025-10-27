{ pkgs, ... }:
{
  imports = [
    ./sway.nix
    ./niri.nix
    ./lock.nix
    ./idle.nix
    ./gtk.nix
    ./kbptr.nix
    ./which-key.nix
  ];

  services.gnome-keyring.enable = true;
  services.polkit-gnome.enable = true;

  programs.iio-sway = {
    enable = true;
  };

  home.packages = with pkgs; [
    wl-clipboard
    brightnessctl
    grim
    slurp
    swappy
    imv
    wf-recorder
    wayland-utils
    wayland-protocols
    playerctl
    tofi
    workstyle
    swayest-workstyle
    swaybg
    swayidle
    pamixer
    wlopm
  ];
}
