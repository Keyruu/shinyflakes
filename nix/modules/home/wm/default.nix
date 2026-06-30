{ pkgs, ... }:
{
  imports = [
    ./niri
    ./kanshi.nix
    ./lock.nix
    # ./idle.nix
    ./gtk.nix
    ./kbptr.nix
    ./which-key.nix
  ];

  services.gnome-keyring.enable = true;
  services.polkit-gnome.enable = true;

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
    swaybg
    swayidle
    pamixer
    wlopm
    gcr
  ];
}
