{ pkgs, ... }:
{
  imports = [
    ./audio.nix
    ./1password.nix
    ./kbptr.nix
    ./gaming.nix
    ./battery.nix
    ./wireguard.nix
  ];

  programs = {
    nix-ld.enable = true;
    kdeconnect.enable = true;
    firefox.enable = true;
    fish.enable = true;
    ydotool.enable = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    neovim
    lshw
    wezterm
    git
    kitty
    evtest
    wev
    vlc
    cifs-utils
    nautilus
  ];

  services.kanata = {
    enable = true;
    keyboards.lenovo.configFile = ../../../home/common/kanata.kbd;
  };

  services.gvfs.enable = true; # Mount, trash, and other functionalities

  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  security.pam.services.hyprlock = { };
  security.pam.services.swaylock = {
    text = ''
      auth sufficient pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
    '';
  };
}
