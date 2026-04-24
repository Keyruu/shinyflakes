{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libnotify
    mesa
  ];

  # GTK3 schemas (e.g. org.gtk.Settings.FileChooser) needed for Qt apps using
  # the gtk3 platform theme — without this, file dialogs crash
  environment.sessionVariables.XDG_DATA_DIRS = [
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  ];

  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;
}
