{
  config,
  pkgs,
  ...
}:
let
  # Theme variables (similar to Hyprland setup)
  border-size = config.theme.border-size or 1;
  gaps-in = config.theme.gaps-in or 5;
  gaps-out = config.theme.gaps-out or 10;
in
{
  home.packages = with pkgs; [
    # Wayland utilities (similar to Hyprland packages)
    wl-clipboard
    brightnessctl
    grim
    slurp
    swappy
    imv
    wf-recorder
    wayland-utils
    wayland-protocols
    playerctl
    tofi
    workstyle
    swayest-workstyle
  ];

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = rec {
      modifier = "Alt"; # Same as Hyprland $mod

      terminal = "wezterm";
      menu = "tofi-drun | xargs swaymsg exec --";

      window = {
        border = border-size;
        titlebar = false;
      };

      gaps = {
        inner = gaps-in;
        outer = gaps-out;
      };

      focus = {
        followMouse = "yes";
        mouseWarping = false;
        newWindow = "smart";
      };

      bars = [ ];

      startup = [
        { command = "dbus-update-activation-environment --systemd --all"; }
        { command = "clipse -listen"; }
        { command = "walker --gapplication-service"; }
        { command = "sherlock --daemonize"; }
        { command = "1password --ozone-platform-hint=x11"; }
        { command = "sworkstyle"; }
        { command = "sway-focus-tracker"; }
      ];

      output = {
        "eDP-1" = {
          mode = "1920x1200@60Hz";
          pos = "0 0";
          transform = "normal";
        };
        "Huawei Technologies Co., Inc. XWU-CBA 0x00000001" = {
          mode = "2560x1440@143.972Hz";
          pos = "0 -1440";
          transform = "normal";
        };
      };

      # Workspace assignments (matching Hyprland)
      workspaceOutputAssign = [
        {
          workspace = "1";
          output = "DP-5";
        }
        {
          workspace = "2";
          output = "DP-5";
        }
        {
          workspace = "3";
          output = "DP-5";
        }
        {
          workspace = "4";
          output = "eDP-1";
        }
        {
          workspace = "5";
          output = "eDP-1";
        }
        {
          workspace = "6";
          output = "eDP-1";
        }
      ];

      # Window rules (matching Hyprland windowrule)
      window.commands = [
        {
          criteria = {
            app_id = "clipse";
          };
          command = "floating enable, resize set 622 652";
        }
        {
          criteria = {
            app_id = "zen";
          };
          command = "move container to workspace number 1";
        }
        {
          criteria = {
            app_id = "org.wezfurlong.wezterm";
          };
          command = "move container to workspace number 3";
        }
        {
          criteria = {
            app_id = "spotify_player";
          };
          command = "move container to workspace number 4";
        }
      ];

      # Input configuration (matching Hyprland input settings)
      input = {
        "*" = {
          xkb_options = "caps:escape";
          repeat_delay = "300";
          repeat_rate = "50";
        };
        "type:touchpad" = {
          dwt = "enabled";
          tap = "enabled";
          natural_scroll = "disabled";
          click_method = "clickfinger";
        };
        "type:keyboard" = {
          xkb_numlock = "enabled";
        };
      };

      # Key bindings (adapted from Hyprland binds.nix)
      keybindings =
        {
          # Application shortcuts
          "${modifier}+e" = "exec focusOrOpen wezterm org.wezfurlong.wezterm";
          "${modifier}+c" = "exec focusOrOpen zen zen";
          "${modifier}+m" =
            "workspace number 4; exec focusOrOpen \"foot --app-id spotify_player spotify_player\" spotify_player";
          "${modifier}+w" = "exec focusOrOpen obsidian obsidian";

          # Window management (vim-style navigation)
          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";
          "${modifier}+Shift+h" = "move left";
          "${modifier}+Shift+j" = "move down";
          "${modifier}+Shift+k" = "move up";
          "${modifier}+Shift+l" = "move right";

          # Arrow key alternatives
          "${modifier}+Left" = "focus left";
          "${modifier}+Down" = "focus down";
          "${modifier}+Up" = "focus up";
          "${modifier}+Right" = "focus right";
          "${modifier}+Shift+Left" = "move left";
          "${modifier}+Shift+Down" = "move down";
          "${modifier}+Shift+Up" = "move up";
          "${modifier}+Shift+Right" = "move right";

          # Window actions
          "Super+q" = "kill"; # Close window (matching Hyprland $otherMod)
          "${modifier}+t" = "floating toggle";
          "${modifier}+f" = "fullscreen toggle";
          "${modifier}+Tab" = "workspace back_and_forth";
          "${modifier}+Comma" = "layout toggle stacking tabbed";
          "${modifier}+Period" = "layout toggle splitv splith";

          # Launchers and utilities
          "Super+space" = "exec sherlock";
          "Super+Shift+space" = "exec tofi-drun | xargs swaymsg exec --";
          "Super+x" = "exec powermenu";
          # "Super+Shift+l" = "exec pidof swaylock || swaylock";
          "Super+Shift+v" = "exec foot --app-id clipse sh -c clipse";
          "Super+Shift+l" = "exec pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";

          # Screenshots
          "Print" = "exec grim -g \"$(slurp)\" - | wl-copy";
          "Super+Shift+4" = "exec grim -g \"$(slurp)\" - | wl-copy";

          # Copy/paste shortcuts (matching Hyprland)
          "Super+c" = "exec copyPasteShortcut copy org.wezfurlong.wezterm";
          "Super+v" = "exec copyPasteShortcut paste org.wezfurlong.wezterm";
          "Super+a" = "exec wtype -M ctrl -k a";
          "Super+t" = "exec wtype -M ctrl -k t";
          "Super+k" = "exec wtype -M ctrl -k k";
          "Super+w" = "exec wtype -M ctrl -k w";

          # Layout
          "${modifier}+v" = "splitv";
          "${modifier}+b" = "splith";

          # Resize mode
          "${modifier}+r" = "mode resize";

          # Media keys
          "XF86AudioMute" = "exec sound-toggle";
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioNext" = "exec playerctl next";
          "XF86AudioPrev" = "exec playerctl previous";
          "XF86AudioRaiseVolume" = "exec sound-up";
          "XF86AudioLowerVolume" = "exec sound-down";
          "XF86MonBrightnessUp" = "exec brightness-up";
          "XF86MonBrightnessDown" = "exec brightness-down";

          # Workspace switching (1-9)
        }
        // builtins.listToAttrs (
          builtins.concatLists (
            builtins.genList (
              i:
              let
                ws = toString (i + 1);
              in
              [
                {
                  name = "${modifier}+${ws}";
                  value = "workspace number ${ws}";
                }
                {
                  name = "${modifier}+Shift+${ws}";
                  value = "move container to workspace number ${ws}";
                }
              ]
            ) 9
          )
        );

      # Mouse bindings
      floating.modifier = modifier;

      # Resize mode
      modes = {
        resize = {
          "h" = "resize shrink width 10px";
          "j" = "resize grow height 10px";
          "k" = "resize shrink height 10px";
          "l" = "resize grow width 10px";
          "Left" = "resize shrink width 10px";
          "Down" = "resize grow height 10px";
          "Up" = "resize shrink height 10px";
          "Right" = "resize grow width 10px";
          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };
    };

    # Extra configuration for environment variables (matching Hyprland env)
    extraConfig = ''
      # Environment variables
      exec systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
      exec dbus-update-activation-environment --systemd XDG_SESSION_TYPE XDG_CURRENT_DESKTOP

      # Lid switch
      bindswitch --reload --locked lid:on exec pidof swaylock || swaylock
    '';

    # Sway-specific settings
    extraSessionCommands = ''
      export XDG_SESSION_TYPE=wayland
      export XDG_CURRENT_DESKTOP=sway
      export MOZ_ENABLE_WAYLAND=1
      export ANKI_WAYLAND=1
      export NIXOS_OZONE_WL=1
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export ELECTRON_OZONE_PLATFORM_HINT=auto
      export SDL_VIDEODRIVER=wayland
      export CLUTTER_BACKEND=wayland
      export DIRENV_LOG_FORMAT=""
    '';
  };
}
