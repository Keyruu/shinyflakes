{
  config,
  inputs,
  ...
}:
let
  t = config.user.theme;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  xdg.dataFile."noctalia/plugins/calendar-event".source = ./noctalia-plugins/calendar-event;

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    customPalettes.custom = {
      dark = {
        mPrimary = t.accent;
        mOnPrimary = t.onAccent;
        mSecondary = t.colors.blue;
        mOnSecondary = t.onAccent;
        mTertiary = t.foreground;
        mOnTertiary = t.onAccent;
        mError = t.colors.red;
        mOnError = t.onAccent;
        mSurface = t.background;
        mOnSurface = t.foreground;
        mSurfaceVariant = t.surface;
        mOnSurfaceVariant = t.muted;
        mOutline = t.border;
        mShadow = "#000000";
        mHover = t.elevated;
        mOnHover = t.foreground;
        terminal = {
          background = t.background;
          foreground = t.foreground;
          cursor = t.foreground;
          cursorText = t.background;
          selectionBg = t.foreground;
          selectionFg = t.background;
          normal = {
            black = t.background;
            red = t.colors.red;
            green = t.colors.green;
            yellow = t.colors.yellow;
            blue = t.colors.blue;
            magenta = t.colors.magenta;
            cyan = t.colors.cyan;
            white = t.foreground;
          };
          bright = {
            black = t.muted;
            red = t.colors.red;
            green = t.colors.green;
            yellow = t.colors.yellow;
            blue = t.colors.blue;
            magenta = t.colors.magenta;
            cyan = t.colors.cyan;
            white = t.foreground;
          };
        };
      };
    };

    settings = {
      shell = {
        font_family = config.user.font;
        setup_wizard_enabled = false;
        telemetry_enabled = false;
        panel = {
          launcher_placement = "attached";
          clipboard_placement = "attached";
          control_center_placement = "attached";
          wallpaper_placement = "attached";
          session_placement = "attached";
          open_near_click_launcher = true;
          open_near_click_clipboard = true;
          open_near_click_control_center = true;
          open_near_click_wallpaper = true;
          open_near_click_session = true;
        };
      };

      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "custom";
      };

      bar.main = {
        position = "top";
        background_opacity = 0.0;
        capsule = true;
        monitor.laptop = {
          match = "eDP-1";
          scale = 0.8;
        };
        margin_edge = 4;
        margin_ends = 18;
        start = [
          "control-center"
          "workspaces"
          "taskbar"
          "active_window"
        ];
        center = [ "media" ];
        end = [
          "tray"
          "calendar-widget"
          "network"
          "bluetooth"
          "sysmon"
          "ram"
          "battery"
          "volume"
          "input_volume"
          "clock"
          "caffeine"
          "notifications"
        ];
      };

      widget = {
        control-center = {
          custom_image = ./noctalia-plugins/nix-snowflake.svg;
          custom_image_colorize = true;
        };
        workspaces = {
          display = "name";
          hide_when_empty = true;
          max_label_chars = 6;
          minimal = true;
        };
        taskbar = {
          only_active_workspace = true;
        };
        calendar-widget = {
          type = "local/calendar-event:widget";
        };
        sysmon = {
          type = "sysmon";
        };
        clock = {
          format = "{:%d.%m. %H:%M}";
          vertical_format = "{:%H\\n%M}";
        };
        network = {
          show_label = false;
        };
      };

      wallpaper = {
        enabled = true;
        default.path = ../themes/dark-bg.jpg;
      };

      notification = {
        enable_daemon = true;
        filter = {
          discord = {
            enabled = true;
            match = "discord";
            play_sound = false;
          };
          firefox = {
            enabled = true;
            match = "firefox";
            play_sound = false;
          };
          slack = {
            enabled = true;
            match = "Slack";
            play_sound = false;
          };
          opencode = {
            enabled = true;
            match = "opencode";
            play_sound = false;
          };
        };
      };

      location = {
        address = "Munich, Germany";
      };

      lockscreen.enabled = false;
      idle = {
        behavior = {
          lock = {
            enabled = false;
          };
          screen-off = {
            enabled = false;
          };
        };
      };

      dock.enabled = false;

      plugins = {
        enabled = [
          "noctalia/notes-scratchpad"
          "local/calendar-event"
        ];
      };
    };
  };

  xdg.desktopEntries = {
    caffeine = {
      name = "Caffeine";
      exec = "noctalia msg caffeine-toggle";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "caffeine";
    };

    notification-center = {
      name = "Notification Center";
      exec = "noctalia msg panel-toggle control-center notifications";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "notifications";
    };

    clear-notification = {
      name = "Clear Notifications";
      exec = "noctalia msg notification-clear-history";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "notification-disabled";
    };

    do-not-disturb = {
      name = "Toggle DND";
      exec = "noctalia msg notification-dnd-toggle";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "notification-disabled";
    };
  };
}
