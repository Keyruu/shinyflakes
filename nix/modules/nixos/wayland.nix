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

  programs.regreet = {
    enable = true;
    theme.package = pkgs.canta-theme;
    settings = {
      background = {
        path = ../home/linux/themes/dark-bg.jpg;
        fit = "Fill";
      };
      GTK = {
        application_prefer_dark_theme = true;
      };
    };
    extraCss = ''
      window {
        background: #1a1b26;
      }

      selection {
        color: #cdd6f4;
        background: rgba(255, 255, 255, 0.2);
      }

      frame,
      image,
      grid {
        border: 0;
        color: #cdd6f4;
      }

      frame {
        box-shadow: 0 0 0.5rem #4079d6;
      }

      button,
      entry,
      combobox,
      combobox entry,
      combobox popover,
      combobox popover contents,
      combobox popover contents modelbutton,
      combobox button,
      combobox window menu,
      frame,
      input {
        color: #cdd6f4;
        border-color: rgba(12, 14, 15, 0.9);
        background: rgba(12, 14, 15, 0.9);
        border-radius: 20px;
      }

      button:hover,
      combobox:hover,
      combobox modelbutton:hover {
        border-color: #11111b;
        background: #11111b;
      }

      button.suggested-action {
        color: #cdd6f4;
        border-color: #4079d6;
        background: #4079d6;
      }

      button.suggested-action:hover {
        border-color: #3668b5;
        background: #3668b5;
      }

      button.destructive-action {
        color: #cdd6f4;
        border-color: #f38ba8;
        background: #f38ba8;
      }

      button.destructive-action:hover {
        border-color: #f26e8c;
        background: #f26e8c;
      }

      infobar,
      infobar box {
        border: 0;
        background: rgba(12, 14, 15, 0.9);
        color: #f38ba8;
      }
    '';
  };

  environment.etc."greetd/niri.kdl".text = # kdl
    ''
      output "eDP-1" {
          mode "1920x1200@60"
          scale 1.0
          position x=0 y=0
      }
      spawn-sh-at-startup "${pkgs.regreet}/bin/regreet; ${pkgs.niri-unstable}/bin/niri msg action quit --skip-confirmation"
      hotkey-overlay {
        skip-at-startup
      }
    '';

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri-unstable}/bin/niri --config /etc/greetd/niri.kdl";
        user = "greeter";
      };
    };
  };

  services.displayManager.sessionPackages = with pkgs; [
    niri-unstable
    sway
  ];

  security.pam.services.greetd.fprintAuth = false;
}
