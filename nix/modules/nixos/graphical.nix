{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libnotify
    mesa
  ];

  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;
}
