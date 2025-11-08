{
  lib,
  pkgs,
  ...
}:
{
  security.pam.services = {
    hyprlock.fprintAuth = false; # use hyprlock's built in fprint implementation
  };

  services.xserver.enable = lib.mkForce false;

  environment.variables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "niri";
    XDG_CURRENT_DESKTOP = "niri";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_DBUS_REMOTE = "1";
    ANKI_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "gtk3";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QS_ICON_THEME = "Papirus";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    DIRENV_LOG_FORMAT = "";
  };

  xdg.portal = {
    enable = true;
    wlr.enable = false;
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Access" = "gtk";
      "org.freedesktop.impl.portal.Notification" = "gtk";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
      "org.freedesktop.impl.portal.FileChooser" = "gtk";
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  environment.etc."issue".text = # env
    ''
      ███▄▄▄▄    ▄█  ▀████     ████▀  ▄██████▄     ▄████████
      ███▀▀▀██▄ ███    ███    ████▀  ███    ███   ███    ███
      ███   ███ ███     ███   ███    ███    ███   ███    █▀
      ███   ███ ███     ▀███▄███▀    ███    ███   ███
      ███   ███ ███     ████▀██▄     ███    ███ ▀███████████
      ███   ███ ███     ███  ▀███    ███    ███          ███
      ███   ███ ███   ▄███     ███▄  ███    ███    ▄█    ███
       ▀█   █▀  █▀   ████       ███▄  ▀██████▀   ▄████████▀

      omarchy who?
    '';

  services.greetd =
    let
      tuigreetTheme = {
        border = "blue";
        text = "cyan";
        prompt = "white";
        time = "white";
        action = "white";
        button = "cyan";
        container = "darkgray";
        input = "white";
      };

      themeString = lib.pipe tuigreetTheme [
        (lib.mapAttrsToList (k: v: "${k}=${v}"))
        (lib.concatStringsSep ";")
      ];

      tuigreetOptions = [
        "--issue"
        "--asterisks"
        "--time"
        "--user-menu"
        "--greet-align left"
        "--theme '${themeString}'"
      ];

      tuigreetCmd = lib.concatStringsSep " " ([ "${pkgs.tuigreet}/bin/tuigreet" ] ++ tuigreetOptions);
    in
    {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          command = tuigreetCmd;
          user = "greeter";
        };
      };
    };

  services.displayManager = {
    sessionPackages = with pkgs; [
      niri-unstable
      sway
    ];
  };

  security.pam.services = {
    login.fprintAuth = false;
    greetd.fprintAuth = false;
  };
}
