{
  inputs,
  pkgs,
  lib,
  perSystem,
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
        MOZ_ENABLE_WAYLAND = "1";
        MOZ_DBUS_REMOTE = "1";
        ANKI_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
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
            "${../themes/lucy.jpeg}"
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

      # Output configuration matching your Sway outputs
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
            x = 0;
            y = -1440;
          };
        };
        "Samsung Electric Company C34H89x H4ZT801005" = {
          mode = {
            width = 3440;
            height = 1440;
            refresh = 99.982;
          };
          scale = 1.0;
          position = {
            x = 0;
            y = -1440;
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

        gaps = 0;
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
              "nirius focurs-or-spawn -a ${appId} ${command}";
        in
        {
          # Media keys (matching your extraConfig)
          "XF86AudioRaiseVolume".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-i"
            "5"
          ];
          "XF86AudioLowerVolume".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-d"
            "5"
          ];
          "XF86AudioMute".action.spawn = [
            "${pkgs.pamixer}/bin/pamixer"
            "-t"
          ];
          "XF86AudioPlay".action.spawn = [
            "${pkgs.playerctl}/bin/playerctl"
            "play-pause"
          ];
          "XF86AudioNext".action.spawn = [
            "${pkgs.playerctl}/bin/playerctl"
            "next"
          ];
          "XF86AudioPrev".action.spawn = [
            "${pkgs.playerctl}/bin/playerctl"
            "previous"
          ];

          "XF86MonBrightnessUp".action.spawn = [
            "${pkgs.brightnessctl}/bin/brightnessctl"
            "set"
            "+10%"
          ];
          "XF86MonBrightnessDown".action.spawn = [
            "${pkgs.brightnessctl}/bin/brightnessctl"
            "set"
            "10%-"
          ];

          # Application shortcuts using nirius focus-or-spawn
          "Alt+E".action.spawn-sh = focusOrSpawn "term" "Alacritty" "alacritty";
          "Alt+C".action.spawn-sh = focusOrSpawn "browse" "zen" "zen";
          "Alt+V".action.spawn-sh = focusOrSpawn "ide" "dev.zed.Zed" "zeditor";
          "Alt+M".action.spawn-sh = focusOrSpawn "media" "spotify" "spotify";
          "Alt+A".action.spawn-sh = focusOrSpawn "social" "Slack" "slack";

          # Special character
          "Alt+S".action.spawn = [
            "${pkgs.wtype}/bin/wtype"
            "ß"
          ];

          # Window management (vim-style navigation)
          "Alt+H".action.focus-column-or-monitor-left = [ ];
          "Alt+J".action.focus-window-or-workspace-down = [ ];
          "Alt+K".action.focus-window-or-workspace-up = [ ];
          "Alt+L".action.focus-column-or-monitor-right = [ ];
          "Alt+Shift+H".action.move-column-left = [ ];
          "Alt+Shift+J".action.move-window-down-or-to-workspace-down = [ ];
          "Alt+Shift+K".action.move-window-up-or-to-workspace-up = [ ];
          "Alt+Shift+L".action.move-column-right = [ ];
          "Ctrl+Alt+J".action.focus-monitor-down = [ ];
          "Ctrl+Alt+K".action.focus-monitor-up = [ ];
          "Alt+Q".action.focus-monitor-next = [ ];
          "Alt+Shift+Q".action.move-window-to-monitor-next = [ ];

          # Arrow key alternatives
          "Alt+Left".action.focus-column-left = [ ];
          "Alt+Down".action.focus-window-down = [ ];
          "Alt+Up".action.focus-window-up = [ ];
          "Alt+Right".action.focus-column-right = [ ];
          "Alt+Shift+Left".action.move-column-left = [ ];
          "Alt+Shift+Down".action.move-window-down = [ ];
          "Alt+Shift+Up".action.move-window-up = [ ];
          "Alt+Shift+Right".action.move-column-right = [ ];

          # Window actions
          "Super+Q".action.close-window = [ ];
          "Alt+T".action.toggle-window-floating = [ ];
          "Alt+F".action.maximize-column = [ ];
          "Alt+Tab".action.spawn = [
            "vicinae"
            "vicinae://extensions/vicinae/wm/switch-windows"
          ];
          "Alt+Comma".action.consume-window-into-column = [ ];
          "Alt+Period".action.expel-window-from-column = [ ];

          # Launchers and utilities
          "Super+Space".action.spawn = [
            "vicinae"
            "toggle"
          ];
          "Alt+Space".action.spawn = "scratch-niri";
          "Super+Shift+Space".action.spawn = [
            "1password"
            "--ozone-platform-hint=wayland"
            "--quick-access"
            "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations"
          ];
          "Super+Shift+L".action.spawn = [
            "loginctl"
            "lock-session"
          ];
          "Super+Shift+V".action.spawn = [
            "vicinae"
            "vicinae://extensions/vicinae/clipboard/history"
          ];
          "Super+X".action.spawn = [
            "${pkgs.wl-kbptr}/bin/wl-kbptr"
            "-c"
            "$HOME/.config/wl-kbptr/floating"
          ];

          "Super+Shift+4".action.screenshot = [ ];

          # Copy/paste shortcuts
          "Super+C".action.spawn = [
            "copyPasteShortcut"
            "copy"
            "org.wezfurlong.wezterm"
            "Alacritty"
            "dev.zed.Zed"
            "foot"
            "scratchpad"
          ];
          "Super+V".action.spawn = [
            "copyPasteShortcut"
            "paste"
            "org.wezfurlong.wezterm"
            "Alacritty"
            "dev.zed.Zed"
            "foot"
            "scratchpad"
          ];
          "Super+A".action.spawn = [
            "${pkgs.wtype}/bin/wtype"
            "-M"
            "ctrl"
            "-k"
            "a"
          ];
          "Super+T".action.spawn = [
            "${pkgs.wtype}/bin/wtype"
            "-M"
            "ctrl"
            "-k"
            "t"
          ];
          "Super+K".action.spawn = [
            "${pkgs.wtype}/bin/wtype"
            "-M"
            "ctrl"
            "-k"
            "k"
          ];
          "Super+W".action.spawn = [
            "${pkgs.wtype}/bin/wtype"
            "-M"
            "ctrl"
            "-k"
            "w"
          ];
          "Super+R".action.spawn = [
            "${pkgs.wtype}/bin/wtype"
            "-M"
            "ctrl"
            "-k"
            "r"
          ];
          "Super+F".action.spawn = [
            "${pkgs.wtype}/bin/wtype"
            "-M"
            "ctrl"
            "-k"
            "f"
          ];

          # Resize mode equivalent
          "Alt+R".action.switch-preset-column-width = [ ];
          "Alt+G".action.spawn = [
            "wlr-which-key"
            "--initial-keys"
            "n"
          ];
          "Alt+W".action.spawn = [
            "wlr-which-key"
            "--initial-keys"
            "n w"
          ];

          # Workspace switching (1-9)
          "Alt+1".action.focus-workspace = 1;
          "Alt+2".action.focus-workspace = 2;
          "Alt+3".action.focus-workspace = 3;
          "Alt+4".action.focus-workspace = 4;
          "Alt+5".action.focus-workspace = 5;
          "Alt+6".action.focus-workspace = 6;
          "Alt+7".action.focus-workspace = 7;
          "Alt+8".action.focus-workspace = 8;
          "Alt+9".action.focus-workspace = 9;

          # Move to workspace
          "Alt+Shift+1".action.move-column-to-workspace = 1;
          "Alt+Shift+2".action.move-column-to-workspace = 2;
          "Alt+Shift+3".action.move-column-to-workspace = 3;
          "Alt+Shift+4".action.move-column-to-workspace = 4;
          "Alt+Shift+5".action.move-column-to-workspace = 5;
          "Alt+Shift+6".action.move-column-to-workspace = 6;
          "Alt+Shift+7".action.move-column-to-workspace = 7;
          "Alt+Shift+8".action.move-column-to-workspace = 8;
          "Alt+Shift+9".action.move-column-to-workspace = 9;
        };

      workspaces = {
        "01-browse" = {
          open-on-output = "DP-5";
          name = "browse";
        };
        "02-ide" = {
          open-on-output = "DP-5";
          name = "ide";
        };
        "03-term" = {
          open-on-output = "DP-5";
          name = "term";
        };
        "04-media" = {
          open-on-output = "eDP-1";
          name = "media";
        };
        "05-social" = {
          open-on-output = "eDP-1";
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
          matches = [ { app-id = "^zen$"; } ];
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
          ];
          open-on-workspace = "social";
          default-column-width = {
            proportion = 0.666;
          };
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
