{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./binds.nix
    ./lock.nix
    ./gtk.nix
    ./kbptr.nix

    inputs.iio-sway.homeManagerModules.default
  ];

  services.gnome-keyring.enable = true;
  services.polkit-gnome.enable = true;

  programs.iio-sway = {
    enable = true;
  };

  home.packages = with pkgs; [
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
    swaybg
    swayidle
    pamixer
    wlopm
  ];

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = rec {
      modifier = "Alt"; # Same as Hyprland $mod
      floating.modifier = modifier;

      window = {
        border = 1;
        titlebar = true;
      };

      gaps = {
        inner = 0;
        outer = 0;
      };

      focus = {
        followMouse = "yes";
        mouseWarping = "container";
        newWindow = "focus";
      };

      bars = [ ];

      startup = [
        { command = "dbus-update-activation-environment --systemd --all"; }
        { command = "clipse -listen"; }
        { command = "1password --ozone-platform-hint=wayland --silent"; }
        { command = "sworkstyle"; }
        { command = "iio-sway"; }
        { command = "distrobox enter mdm -- exit"; }
      ];

      output = {
        "*" = {
          bg = "${../themes/blue-bg.jpg} fill";
        };
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
        "Samsung Electric Company C34H89x H4ZT801005" = {
          mode = "3440x1440@99.982Hz";
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
          workspace = "1";
          output = "DP-3";
        }
        {
          workspace = "2";
          output = "DP-3";
        }
        {
          workspace = "3";
          output = "DP-3";
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
            title = ".*";
          };
          command = "title_format \"<b>%title</b> (%app_id)\"";
        }
        {
          criteria = {
            app_id = "scratchpad";
          };
          command = "floating enable, opacity 0.96, move scratchpad, scratchpad show, resize set width 88 ppt height 92 ppt, border none";
        }
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
            app_id = "dev.zed.Zed";
          };
          command = "move container to workspace number 2";
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
        {
          criteria = {
            app_id = "Slack";
          };
          command = "move container to workspace number 5";
        }
        {
          criteria = {
            app_id = "signal";
          };
          command = "move container to workspace number 5";
        }
        {
          criteria = {
            app_id = "vesktop";
          };
          command = "move container to workspace number 5";
        }
      ];

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
          xkb_layout = "us";
          xkb_options = "caps:escape";
          xkb_numlock = "enabled";
        };
        "type:pointer" = {
          pointer_accel = "-1";
        };
      };

      fonts = {
        names = [ "pango:JetBrains Mono" ];
        size = 10.0;
      };

      colors = {
        focused = {
          border = "#003a6a"; # base0D - Blue accent
          background = "#003a6a"; # base02 - Selection background
          text = "#cdd6f4"; # base05 - Default foreground
          indicator = "#003a6a"; # base0D - Blue accent
          childBorder = "#003a6a"; # base0D - Blue accent
        };

        focusedInactive = {
          border = "#45475a"; # base03 - Comments/invisibles
          background = "#202324"; # base01 - Lighter background
          text = "#cdd6f4"; # base05 - Default foreground
          indicator = "#45475a"; # base03 - Comments/invisibles
          childBorder = "#45475a"; # base03 - Comments/invisibles
        };

        unfocused = {
          border = "#45475a"; # base03 - Comments/invisibles
          background = "#0c0e0f"; # base00 - Default background
          text = "#585b70"; # base04 - Dark foreground
          indicator = "#45475a"; # base03 - Comments/invisibles
          childBorder = "#45475a"; # base03 - Comments/invisibles
        };

        urgent = {
          border = "#f38ba8"; # base08 - Variables/errors (red/pink)
          background = "#f38ba8"; # base08 - Variables/errors
          text = "#0c0e0f"; # base00 - Dark text on bright background
          indicator = "#f38ba8"; # base08 - Variables/errors
          childBorder = "#f38ba8"; # base08 - Variables/errors
        };

        placeholder = {
          border = "#45475a"; # base03 - Comments/invisibles
          background = "#0c0e0f"; # base00 - Default background
          text = "#585b70"; # base04 - Dark foreground
          indicator = "#45475a"; # base03 - Comments/invisibles
          childBorder = "#45475a"; # base03 - Comments/invisibles
        };
      };
    };

    # Extra configuration for environment variables (matching Hyprland env)
    extraConfig = ''
      bindsym --locked XF86AudioRaiseVolume exec --no-startup-id pamixer -i 5 #to increase 5%
      bindsym --locked XF86AudioLowerVolume exec --no-startup-id pamixer -d 5 #to decrease 5%
      bindsym --locked XF86AudioMute exec --no-startup-id pamixer -t
      bindsym --locked XF86AudioPlay exec playerctl play-pause
      bindsym --locked XF86AudioNext exec playerctl next
      bindsym --locked XF86AudioPrev exec playerctl previous

      # Brightness controls
      bindsym --locked XF86MonBrightnessUp exec --no-startup-id brightnessctl set +10%
      bindsym --locked XF86MonBrightnessDown exec --no-startup-id brightnessctl set 10%-
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
      export MOZ_ENABLE_WAYLAND=1
    '';
  };
}
