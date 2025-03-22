{config, pkgs, inputs, ...}: {
  imports = [
    ./polkitagent.nix
  ];

  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6ct
    hyprpicker
    swappy
    imv
    wf-recorder
    wlr-randr
    wl-clipboard
    brightnessctl
    gnome-themes-extra
    libva
    dconf
    wayland-utils
    wayland-protocols
    glib
    direnv
    meson
    clipse
    hyprshot
  ];

  wayland.windowManager.hyprland = let
    border-size = config.theme.border-size;
    gaps-in = config.theme.gaps-in;
    gaps-out = config.theme.gaps-out;
    active-opacity = config.theme.active-opacity;
    inactive-opacity = config.theme.inactive-opacity;
    rounding = config.theme.rounding;
    blur = config.theme.blur;
  in {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;

    plugins = [
      inputs.hyprgrass.packages.${pkgs.system}.default
      inputs.hyprgrass.packages.${pkgs.system}.hyprgrass-pulse
    ];

    settings = {
      "$mod" = "Alt";
      "$otherMod" = "Super";
      "$terminal" = "wezterm";
      "$fileManager" = "dolphin";
      "$menu" = "wofi --show drun";

      exec-once = [
        "dbus-update-activation-environment --systemd --all"
        "hyprswitch init --show-title &"
        "iio-hyprland"
        "clipse -listen"
      ];

      animations = {
        enabled = "no";
      };

      monitor = [
        "eDP-1, 1920x1200@60, 0x0, 1, transform, 0"
        "desc:Huawei Technologies Co. Inc. XWU-CBA 0x00000001,2560x1440@143.97200,0x-1440,1"
        ",prefered,auto,1"
      ];

      bind =
        [
          "$mod, E, exec, focusOrOpen $terminal org.wezfurlong.wezterm 3"
          "$mod, C, exec, focusOrOpen zen zen 1"
          "$mod, M, exec, focusOrOpen spotify spotify 1"
          "$mod, H, movefocus, l"
          "$mod, J, movefocus, d"
          "$mod, K, movefocus, u"
          "$mod, L, movefocus, r"
          ", Print, exec, grimblast copy area"
          "$otherMod, Space, exec, wofi -p \"Apps\" --show drun"
          "$mod, X, exec, powermenu"
          "$otherMod Shift, L, exec, pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock"
          "$otherMod Shift, V, exec, $terminal start --class clipse sh -c clipse"
          "$otherMod Shift, 4, exec, hyprshot -m region --clipboard-only"

          "$mod,Q, killactive," # Close window
          "$mod,T, togglefloating," # Toggle Floating
          "$mod,F, fullscreen"
          "$mod, tab, exec, hyprswitch gui --mod-key alt --key tab --close mod-key-release --reverse-key=key=shift --sort-recent && hyprswitch dispatch"
          "$mod Shift, tab, exec, hyprswitch gui --mod-key alt --key tab --close mod-key-release --reverse-key=key=shift --sort-recent && hyprswitch dispatch -r"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (i:
              let ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );
      
      bindm = [
        "$mod,mouse:272, movewindow" # Move Window (mouse)
        "$mod,R, resizewindow" # Resize Window (mouse)
      ];

      bindl = [
        ",XF86AudioMute, exec, sound-toggle" # Toggle Mute
        ",XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause" # Play/Pause Song
        ",XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next" # Next Song
        ",XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous" # Previous Song
        ",switch:Lid Switch, exec, pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock" # Lock when closing Lid
      ];

      bindle = [
        ",XF86AudioRaiseVolume, exec, sound-up" # Sound Up
        ",XF86AudioLowerVolume, exec, sound-down" # Sound Down
        ",XF86MonBrightnessUp, exec, brightness-up" # Brightness Up
        ",XF86MonBrightnessDown, exec, brightness-down" # Brightness Down
      ];

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "MOZ_ENABLE_WAYLAND,1"
        "ANKI_WAYLAND,1"
        "DISABLE_QT5_COMPAT,0"
        "NIXOS_OZONE_WL,1"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM=wayland,xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "__GL_GSYNC_ALLOWED,0"
        "__GL_VRR_ALLOWED,0"
        "DISABLE_QT5_COMPAT,0"
        "DIRENV_LOG_FORMAT,"
        "WLR_DRM_NO_ATOMIC,1"
        "WLR_BACKEND,vulkan"
        "WLR_RENDERER,vulkan"
        "WLR_NO_HARDWARE_CURSORS,1"
        "XDG_SESSION_TYPE,wayland"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
      ];

      cursor = {
        no_hardware_cursors = true;
        default_monitor = "eDP-1";
      };

      general = {
        resize_on_border = true;
        gaps_in = gaps-in;
        gaps_out = gaps-out;
        border_size = border-size;
        layout = "master";
      };

      decoration = {
        active_opacity = active-opacity;
        inactive_opacity = inactive-opacity;
        rounding = rounding;
        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
        };
        blur = {
          enabled = if blur then "true" else "false";
          size = 18;
        };
      };

      master = {
        new_status = true;
        allow_small_split = true;
        mfact = 0.5;
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_cancel_ratio = 0.15;
      };

      misc = {
        vfr = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        disable_autoreload = true;
        focus_on_activate = true;
        new_window_takes_over_fullscreen = 2;
      };

      windowrulev2 = [
        "float, tag:modal"
        "pin, tag:modal"
        "center, tag:modal"
        "float,class:(clipse)"
        "size 622 652,class:(clipse)"

        "workspace 1, class:(zen)"
        "workspace 3, class:(org.wezfurlong.wezterm)"
      ];

      layerrule = [ "noanim, launcher" "noanim, ^ags-.*" ];

      input = {
        kb_options = "caps:escape";
        follow_mouse = 1;
        sensitivity = 0.5;
        repeat_delay = 300;
        repeat_rate = 50;
        numlock_by_default = true;

        touchpad = {
          natural_scroll = false;
          clickfinger_behavior = true;
        };
      };

      plugins = {
        touch_gestures = {
          hyprgrass-bind = [
            ", edge:d:u, exec, pkill squeekboard || SQUEEKBOARD_DEBUG=force_show squeekboard"
            ", edge:u:d, exec, pkill nwg-drawer || nwg-drawer"
            ", swipe:2:r, workspace, +1"
            ", swipe:2:l, workspace, -1"
            ", swipe:4:l, movetoworkspace, +1"
            ", swipe:4:r, movetoworkspace, -1"
            ", swipe:4:d, killactive"
          ];

          hyprgrass-bindm = [
            ", longpress:2, movewindow"
            ", longpress:3, resizewindow"
          ];
        };

        hyprgrass-pulse = {
          edge = "r";
        };
      };
    };
  };
}
