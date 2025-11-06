{
  inputs,
  pkgs,
  lib,
  perSystem,
  config,
  ...
}:
{
  imports = [
    inputs.niri.homeModules.niri
  ];

  home.packages = with pkgs; [
    perSystem.self.nirius
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
    settings = {
      # Environment variables matching your Sway extraSessionCommands
      environment = {
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "niri";
        XDG_CURRENT_DESKTOP = "niri";
        # XDG_DATA_DIRS = "$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
        MOZ_ENABLE_WAYLAND = "1";
        MOZ_DBUS_REMOTE = "1";
        ANKI_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "gtk3";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "wayland";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        DIRENV_LOG_FORMAT = "";
      };

      xwayland-satellite = {
        enable = true;
        path = lib.getExe pkgs.xwayland-satellite-unstable;
      };

      # Startup commands matching your Sway startup
      spawn-at-startup = [
        {
          command = [
            "niriusd"
          ];
        }
        {
          command = [
            "swaybg"
            "-i"
            "${../themes/dark-bg.jpg}"
            "-m"
            "fill"
          ];
        }
        {
          command = [
            "clipse"
            "-listen"
          ];
        }
        {
          command = [
            "1password"
            "--ozone-platform-hint=wayland"
            "--silent"
          ];
        }
        {
          command = [
            "tailscale"
            "systray"
          ];
        }
        {
          command = [
            "distrobox"
            "enter"
            "mdm"
            "--"
            "exit"
          ];
        }
        {
          command = [
            "${pkgs.dbus}/bin/dbus-update-activation-environment"
            "--systemd"
            "--all"
          ];
        }
      ];

      # Input configuration matching your Sway input settings
      input = {
        keyboard = {
          xkb = {
            layout = "eu";
            options = "caps:escape";
          };
          repeat-delay = 300;
          repeat-rate = 50;
        };
        touchpad = {
          dwt = true;
          dwtp = true;
          tap = true;
          natural-scroll = false;
          click-method = "clickfinger";
        };
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "10%";
        };
        mouse = {
          accel-speed = -1.0;
        };
        warp-mouse-to-focus.enable = true;
        workspace-auto-back-and-forth = false;
      };

      # Output configuration managed by kanshi
      outputs = {
        "eDP-1" = {
          mode = {
            width = 1920;
            height = 1200;
            refresh = 60.0;
          };
          scale = 1.0;
          position = {
            x = 0;
            y = 0;
          };
        };
        "Huawei Technologies Co., Inc. XWU-CBA 0x00000001" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 143.972;
          };
          scale = 1.0;
          position = {
            x = -320;
            y = -1440;
          };
        };
        "LG Electronics LG HDR 4K 0x00073A91" = {
          mode = {
            width = 3840;
            height = 2160;
            refresh = 59.997;
          };
          scale = 1.4;
          position = {
            x = -411;
            y = -1543;
          };
        };
      };

      # Layout configuration matching your Sway window settings
      layout = {
        focus-ring = {
          enable = false;
          width = 1;
          active.color = "#003a6a";
          inactive.color = "#45475a";
        };
        border = {
          enable = true;
          width = 3;
          active.color = "#f5f5f5";
          inactive.color = "#45475a";
        };

        preset-column-widths = [
          { proportion = 0.333; }
          { proportion = 0.5; }
          { proportion = 0.666; }
          { proportion = 1.0; }
        ];
        default-column-width = {
          proportion = 1.0;
        };
        always-center-single-column = true;
        center-focused-column = "on-overflow";

        gaps = 4;
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
      };

      cursor = {
        size = 20;
        theme = "phinger-cursors-light";
      };

      # Keybindings matching your Sway binds
      binds =
        let
          focusOrSpawn =
            workspaceName: appId: command:
            if workspaceName != null then
              "nirius focus-or-spawn -a ${appId} ${command} && niri msg action focus-workspace ${workspaceName}"
            else
              "nirius focus-or-spawn -a ${appId} ${command}";
        in
        {
          # Media keys (matching your extraConfig)
          "XF86AudioRaiseVolume" = {
            action.spawn = [
              "${pkgs.pamixer}/bin/pamixer"
              "-i"
              "5"
            ];
            hotkey-overlay.hidden = true;
          };
          "XF86AudioLowerVolume" = {
            action.spawn = [
              "${pkgs.pamixer}/bin/pamixer"
              "-d"
              "5"
            ];
            hotkey-overlay.hidden = true;
          };
          "XF86AudioMute" = {
            action.spawn = [
              "${pkgs.pamixer}/bin/pamixer"
              "-t"
            ];
            hotkey-overlay.hidden = true;
          };
          "XF86AudioPlay" = {
            action.spawn = [
              "${pkgs.playerctl}/bin/playerctl"
              "play-pause"
            ];
            hotkey-overlay.hidden = true;
          };
          "XF86AudioNext" = {
            action.spawn = [
              "${pkgs.playerctl}/bin/playerctl"
              "next"
            ];
            hotkey-overlay.hidden = true;
          };
          "XF86AudioPrev" = {
            action.spawn = [
              "${pkgs.playerctl}/bin/playerctl"
              "previous"
            ];
            hotkey-overlay.hidden = true;
          };

          "XF86MonBrightnessUp" = {
            action.spawn = [
              "${pkgs.brightnessctl}/bin/brightnessctl"
              "set"
              "+10%"
            ];
            hotkey-overlay.hidden = true;
          };
          "XF86MonBrightnessDown" = {
            action.spawn = [
              "${pkgs.brightnessctl}/bin/brightnessctl"
              "set"
              "10%-"
            ];
            hotkey-overlay.hidden = true;
          };

          # Application shortcuts using nirius focus-or-spawn
          "Alt+E" = {
            action.spawn-sh = focusOrSpawn "term" "Alacritty" "alacritty";
            hotkey-overlay.title = "Terminal";
          };
          "Alt+C" = {
            action.spawn-sh = focusOrSpawn null "zen-beta" "zen";
            hotkey-overlay.title = "Browser";
          };
          "Alt+V" = {
            action.spawn-sh = focusOrSpawn "ide" "dev.zed.Zed" "zeditor";
            hotkey-overlay.title = "Code Editor";
          };
          "Alt+M" = {
            action.spawn-sh = focusOrSpawn "media" "spotify" "spotify";
            hotkey-overlay.title = "Music";
          };
          "Alt+A" = {
            action.spawn-sh = focusOrSpawn "social" "Slack" "slack";
            hotkey-overlay.title = "Slack";
          };

          # Window management (vim-style navigation)
          "Alt+H" = {
            action.focus-column-or-monitor-left = [ ];
            hotkey-overlay.title = "Focus Left";
          };
          "Alt+J" = {
            action.focus-window-or-workspace-down = [ ];
            hotkey-overlay.title = "Focus Down";
          };
          "Alt+K" = {
            action.focus-window-or-workspace-up = [ ];
            hotkey-overlay.title = "Focus Up";
          };
          "Alt+L" = {
            action.focus-column-or-monitor-right = [ ];
            hotkey-overlay.title = "Focus Right";
          };
          "Alt+Shift+H" = {
            action.move-column-left = [ ];
            hotkey-overlay.title = "Move Window Left";
          };
          "Alt+Shift+J" = {
            action.move-window-down-or-to-workspace-down = [ ];
            hotkey-overlay.title = "Move Window Down";
          };
          "Alt+Shift+K" = {
            action.move-window-up-or-to-workspace-up = [ ];
            hotkey-overlay.title = "Move Window Up";
          };
          "Alt+Shift+L" = {
            action.move-column-right = [ ];
            hotkey-overlay.title = "Move Window Right";
          };
          "Ctrl+Alt+J" = {
            action.focus-monitor-down = [ ];
            hotkey-overlay.title = "Focus Monitor Down";
          };
          "Ctrl+Alt+K" = {
            action.focus-monitor-up = [ ];
            hotkey-overlay.title = "Focus Monitor Up";
          };
          "Alt+Q" = {
            action.focus-monitor-next = [ ];
            hotkey-overlay.title = "Next Monitor";
          };
          "Alt+Shift+Q" = {
            action.move-window-to-monitor-next = [ ];
            hotkey-overlay.title = "Move to Next Monitor";
          };

          # Arrow key alternatives (hidden from overlay since vim keys are shown)
          "Alt+Left" = {
            action.focus-column-left = [ ];
            hotkey-overlay.hidden = true;
          };
          "Alt+Down" = {
            action.focus-window-down = [ ];
            hotkey-overlay.hidden = true;
          };
          "Alt+Up" = {
            action.focus-window-up = [ ];
            hotkey-overlay.hidden = true;
          };
          "Alt+Right" = {
            action.focus-column-right = [ ];
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+Left" = {
            action.move-column-left = [ ];
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+Down" = {
            action.move-window-down = [ ];
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+Up" = {
            action.move-window-up = [ ];
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+Right" = {
            action.move-column-right = [ ];
            hotkey-overlay.hidden = true;
          };

          # Window actions
          "Super+Q" = {
            action.close-window = [ ];
            hotkey-overlay.title = "Close Window";
          };
          "Alt+T" = {
            action.toggle-window-floating = [ ];
            hotkey-overlay.title = "Toggle Floating";
          };
          "Alt+F" = {
            action.maximize-column = [ ];
            hotkey-overlay.title = "Maximize Column";
          };
          "Alt+Tab" = {
            action.spawn = [
              "vicinae"
              "vicinae://extensions/vicinae/wm/switch-windows"
            ];
            hotkey-overlay.title = "Switch Windows";
          };
          "Alt+Comma" = {
            action.consume-window-into-column = [ ];
            hotkey-overlay.title = "Stack Window";
          };
          "Alt+Period" = {
            action.expel-window-from-column = [ ];
            hotkey-overlay.title = "Unstack Window";
          };

          # Launchers and utilities
          "Super+Space" = {
            action.spawn = [
              "vicinae"
              "toggle"
            ];
            hotkey-overlay.title = "App Launcher";
          };
          "Alt+Space" = {
            action.spawn = "scratch-niri";
            hotkey-overlay.title = "Scratchpad";
          };
          "Super+Shift+Space" = {
            action.spawn = [
              "1password"
              "--ozone-platform-hint=wayland"
              "--quick-access"
              "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations"
            ];
            hotkey-overlay.title = "1Password";
          };
          "Super+Shift+L" = {
            action.spawn = [
              "loginctl"
              "lock-session"
            ];
            hotkey-overlay.title = "Lock Screen";
          };
          "Super+Shift+V" = {
            action.spawn = [
              "vicinae"
              "vicinae://extensions/vicinae/clipboard/history"
            ];
            hotkey-overlay.title = "Clipboard History";
          };
          "Super+X" = {
            action.spawn = [
              "${pkgs.wl-kbptr}/bin/wl-kbptr"
              "-c"
              "$HOME/.config/wl-kbptr/floating"
            ];
            hotkey-overlay.title = "Keyboard Pointer";
          };

          "Super+Shift+4" = {
            action.screenshot = [ ];
            hotkey-overlay.title = "Screenshot";
          };

          # Copy/paste shortcuts (hidden - transparent to user)
          "Super+C" = {
            action.spawn = [
              "copyPasteShortcut"
              "copy"
              "org.wezfurlong.wezterm"
              "Alacritty"
              "dev.zed.Zed"
              "foot"
              "scratchpad"
            ];
            hotkey-overlay.hidden = true;
          };
          "Super+V" = {
            action.spawn = [
              "copyPasteShortcut"
              "paste"
              "org.wezfurlong.wezterm"
              "Alacritty"
              "dev.zed.Zed"
              "foot"
              "scratchpad"
            ];
            hotkey-overlay.hidden = true;
          };
          "Super+A" = {
            action.spawn = [
              "${pkgs.wtype}/bin/wtype"
              "-M"
              "ctrl"
              "-k"
              "a"
            ];
            hotkey-overlay.hidden = true;
          };
          "Super+T" = {
            action.spawn = [
              "${pkgs.wtype}/bin/wtype"
              "-M"
              "ctrl"
              "-k"
              "t"
            ];
            hotkey-overlay.hidden = true;
          };
          "Super+K" = {
            action.spawn = [
              "${pkgs.wtype}/bin/wtype"
              "-M"
              "ctrl"
              "-k"
              "k"
            ];
            hotkey-overlay.hidden = true;
          };
          "Super+W" = {
            action.spawn = [
              "${pkgs.wtype}/bin/wtype"
              "-M"
              "ctrl"
              "-k"
              "w"
            ];
            hotkey-overlay.hidden = true;
          };
          "Super+R" = {
            action.spawn = [
              "${pkgs.wtype}/bin/wtype"
              "-M"
              "ctrl"
              "-k"
              "r"
            ];
            hotkey-overlay.hidden = true;
          };
          "Super+F" = {
            action.spawn = [
              "${pkgs.wtype}/bin/wtype"
              "-M"
              "ctrl"
              "-k"
              "f"
            ];
            hotkey-overlay.hidden = true;
          };

          # Resize mode equivalent
          "Alt+R" = {
            action.switch-preset-column-width = [ ];
            hotkey-overlay.title = "Cycle Column Width";
          };
          "Alt+G" = {
            action.spawn = [
              "wlr-which-key"
              "--initial-keys"
              "n"
            ];
            hotkey-overlay.title = "Which Key Menu";
          };
          "Alt+W" = {
            action.spawn = [
              "wlr-which-key"
              "--initial-keys"
              "n w"
            ];
            hotkey-overlay.title = "Workspace Menu";
          };

          # Workspace switching (1-9) - hidden from overlay
          "Alt+1" = {
            action.focus-workspace = 1;
            hotkey-overlay.hidden = true;
          };
          "Alt+2" = {
            action.focus-workspace = 2;
            hotkey-overlay.hidden = true;
          };
          "Alt+3" = {
            action.focus-workspace = 3;
            hotkey-overlay.hidden = true;
          };
          "Alt+4" = {
            action.focus-workspace = 4;
            hotkey-overlay.hidden = true;
          };
          "Alt+5" = {
            action.focus-workspace = 5;
            hotkey-overlay.hidden = true;
          };
          "Alt+6" = {
            action.focus-workspace = 6;
            hotkey-overlay.hidden = true;
          };
          "Alt+7" = {
            action.focus-workspace = 7;
            hotkey-overlay.hidden = true;
          };
          "Alt+8" = {
            action.focus-workspace = 8;
            hotkey-overlay.hidden = true;
          };
          "Alt+9" = {
            action.focus-workspace = 9;
            hotkey-overlay.hidden = true;
          };

          # Move to workspace - hidden from overlay
          "Alt+Shift+1" = {
            action.move-column-to-workspace = 1;
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+2" = {
            action.move-column-to-workspace = 2;
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+3" = {
            action.move-column-to-workspace = 3;
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+4" = {
            action.move-column-to-workspace = 4;
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+5" = {
            action.move-column-to-workspace = 5;
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+6" = {
            action.move-column-to-workspace = 6;
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+7" = {
            action.move-column-to-workspace = 7;
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+8" = {
            action.move-column-to-workspace = 8;
            hotkey-overlay.hidden = true;
          };
          "Alt+Shift+9" = {
            action.move-column-to-workspace = 9;
            hotkey-overlay.hidden = true;
          };
        };

      workspaces = {
        "01-browse" = {
          name = "browse";
        };
        "02-ide" = {
          name = "ide";
        };
        "03-term" = {
          name = "term";
        };
        "04-media" = {
          name = "media";
        };
        "05-social" = {
          name = "social";
        };

      };
      # Window rules matching your Sway window.commands
      window-rules = [
        # Title format for all windows
        {
          matches = [ { } ];
          default-column-width = {
            proportion = 1.0;
          };
          geometry-corner-radius = {
            bottom-left = 7.0;
            bottom-right = 7.0;
            top-left = 7.0;
            top-right = 7.0;
          };
          clip-to-geometry = true;
        }
        # Scratchpad
        {
          matches = [ { app-id = "^scratchpad$"; } ];
          opacity = 0.96;
          default-column-width = {
            proportion = 0.88;
          };
          default-window-height = {
            proportion = 0.88;
          };
          open-floating = true;
          open-maximized = false;
        }
        # Clipse
        {
          matches = [ { app-id = "^clipse$"; } ];
          default-column-width = { };
        }
        # Workspace assignments
        {
          matches = [
            { app-id = "^zen$"; }
            { app-id = "^zen-beta$"; }
          ];
          open-on-workspace = "browse";
        }
        {
          matches = [ { app-id = "^dev.zed.Zed$"; } ];
          open-on-workspace = "ide";
        }
        {
          matches = [
            { app-id = "^org.wezfurlong.wezterm$"; }
            { app-id = "^Alacritty$"; }
          ];
          open-on-workspace = "term";
        }
        {
          matches = [
            { app-id = "^spotify_player$"; }
            { app-id = "^spotify$"; }
            { title = "^Picture-in-Picture$"; }
          ];
          open-on-workspace = "media";
          default-column-width = {
            proportion = 0.5;
          };
        }
        {
          matches = [
            { app-id = "^Slack$"; }
            { app-id = "^signal$"; }
            { app-id = "^vesktop$"; }
            { app-id = "^fluffychat$"; }
          ];
          open-on-workspace = "social";
          default-column-width = {
            proportion = 0.666;
          };
        }
        {
          matches = [
            { app-id = "^1Password$"; }
            { app-id = "^signal$"; }
            { app-id = "^vesktop$"; }
            { app-id = "^fluffychat$"; }
          ];
          block-out-from = "screencast";
        }
      ];

      layer-rules = [
        {
          matches = [
            { namespace = "^swaync-notification-window$"; }
          ];
          block-out-from = "screencast";
        }
      ];

      prefer-no-csd = true;

      hotkey-overlay.skip-at-startup = false;

      # keep defaults
      animations = {
        # slowdown = 1.0;
        # window-open = {
        #   kind.easing = {
        #     duration-ms = 150;
        #     curve = "ease-out-expo";
        #   };
        # };
        # window-close = {
        #   kind.easing = {
        #     duration-ms = 150;
        #     curve = "ease-out-quad";
        #   };
        # };
        # workspace-switch = {
        #   kind.spring = {
        #     damping-ratio = 1.0;
        #     stiffness = 1000;
        #     epsilon = 0.0001;
        #   };
        # };
        # window-movement = {
        #   kind.spring = {
        #     damping-ratio = 1.0;
        #     stiffness = 800;
        #     epsilon = 0.0001;
        #   };
        # };
      };

      # Screenshot path (optional)
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
    };
  };
}
