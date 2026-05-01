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

  xdg.mime.defaultApplications = {
    "text/html" = "qutebrowser-open.desktop";
    "x-scheme-handler/http" = "qutebrowser-open.desktop";
    "x-scheme-handler/https" = "qutebrowser-open.desktop";
    "x-scheme-handler/discord" = "vesktop.desktop";
    "x-scheme-handler/sgnl" = "signal.desktop";
    "x-scheme-handler/signalcaptcha" = "signal.desktop";
    "video/mp4" = "mpv.desktop";
    "video/vnd.avi" = "mpv.desktop";
    "image/jpeg" = "imv.desktop";
    "image/png" = "imv.desktop";
    "image/svg+xml" = "imv.desktop";
    "text/plain" = "dev.zed.Zed.desktop";
  };
}
