{ inputs, ... }:
{
  den.aspects.tools.noctalia = {
    homeManager =
      { pkgs, user, ... }:
      let
        t = user.theme;
      in
      {
        imports = [
          inputs.noctalia.homeModules.default
        ];

        home.packages = [ pkgs.rubik ];
        fonts.fontconfig.enable = true;

        xdg.dataFile."noctalia/plugins/calendar-event".source = ./noctalia-plugins/calendar-event;
        xdg.dataFile."noctalia/plugins/pi-herd".source = ./noctalia-plugins/pi-herd;

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
              font_family = "Rubik";
              setup_wizard_enabled = false;
              telemetry_enabled = false;
              time_format = "{:%H:%M}";
              clipboard_auto_paste = "auto";
              launch_apps_as_systemd_services = true;
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
              background_opacity = 0.7;
              compositor_blur = true;
              shadow = false;
              capsule = true;
              capsule_opacity = 1.0;
              margin_edge = 4;
              margin_ends = 24;
              padding = 5;
              widget_spacing = 5;
              font_scale = 0.9;
              monitor.laptop = {
                match = "eDP-1";
                scale = 0.85;
                font_scale = 1.0;
                margin_ends = 18;
              };
              start = [
                "control-center"
                "workspaces"
                "taskbar"
                "active_window"
              ];
              center = [ "group:g2" ];
              end = [
                "tray"
                "pi-herd"
                "calendar-widget"
                "group:g1"
                "caffeine"
                "notifications"
              ];
              capsule_group = [
                {
                  id = "g1";
                  members = [
                    "sysmon"
                    "ram"
                    "network"
                    "bluetooth"
                    "input_volume"
                    "volume"
                    "battery"
                  ];
                  enabled = true;
                  fill = "surface_container";
                  opacity = 1.0;
                  border_width = 1.0;
                  padding = 6.0;
                  accordion = false;
                  accordion_direction = "end";
                }
                {
                  id = "g2";
                  members = [
                    "clock"
                    "media"
                  ];
                  enabled = true;
                  fill = "surface_container";
                  opacity = 1.0;
                  border_width = 1.0;
                  padding = 6.0;
                  widget_spacing = 10;
                  accordion = true;
                  accordion_direction = "end";
                }
              ];
            };

            widget = {
              control-center = {
                custom_image = ./noctalia-plugins/nix-snowflake.svg;
                custom_image_colorize = true;
              };
              workspaces = {
                label_source = "name";
                max_label_chars = 6;
                style = "regular";
              };
              taskbar = {
                only_active_workspace = true;
                group_by_workspace = true;
                group_single_icon_per_app = true;
                show_workspace_label = false;
                workspace_group_capsule = false;
                icon_scale = 0.8;
              };
              calendar-widget = {
                type = "local/calendar-event:widget";
              };
              pi-herd = {
                type = "local/pi-herd:widget";
              };
              sysmon = {
                type = "sysmon";
                stat = "cpu_usage";
              };
              ram = {
                type = "sysmon";
                stat = "ram_pct";
              };
              clock = {
                format = "{:%a %d.%m. %H:%M}";
                vertical_format = "{:%H\\n%M}";
              };
              network = {
                show_label = false;
              };
              battery = {
                hide_when_full = true;
                show_label = false;
              };
              bluetooth.hide_when_no_connected_device = true;
              media.hide_when_idle = true;
            };

            wallpaper = {
              enabled = true;
              fill_mode = "crop";
              default.path = ../../../assets/dark-bg.jpg;
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

            lockscreen = {
              enabled = true;
              lock_before_suspend = true;
            };
            idle.behavior = {
              lock = {
                enabled = true;
                timeout = 300;
                action = "lock";
              };
              screen-off = {
                enabled = true;
                timeout = 310;
                action = "screen_off";
              };
              suspend = {
                enabled = true;
                timeout = 900;
                action = "lock_and_suspend";
              };
            };

            control_center.shortcuts = map (type: { inherit type; }) [
              "wifi"
              "bluetooth"
              "audio"
              "nightlight"
              "caffeine"
              "notification"
            ];

            dock.enabled = false;

            plugins = {
              enabled = [
                "noctalia/notes"
                "local/calendar-event"
                "local/pi-herd"
              ];
            };
          };
        };

        xdg.desktopEntries = {
          caffeine = {
            name = "Caffeine";
            exec = "noctalia msg caffeine-toggle";
            categories = [ "Utility" ];
            icon = "caffeine";
          };

          notification-center = {
            name = "Notification Center";
            exec = "noctalia msg panel-toggle control-center notifications";
            categories = [ "Utility" ];
            icon = "notifications";
          };

          clear-notification = {
            name = "Clear Notifications";
            exec = "noctalia msg notification-clear-history";
            categories = [ "Utility" ];
            icon = "notification-disabled";
          };

          do-not-disturb = {
            name = "Toggle DND";
            exec = "noctalia msg notification-dnd-toggle";
            categories = [ "Utility" ];
            icon = "notification-disabled";
          };

          dms-calendar = {
            name = "Calendar";
            exec = "noctalia msg panel-toggle control-center calendar";
            categories = [ "Office" ];
            icon = "calendar";
          };
        };
      };
  };
}
