{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # ./hy3.nix
    ./polkitagent.nix
    ./binds.nix
    ./touch.nix
    ./kbptr.nix
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
    hyprshot
    tofi
  ];

  wayland.windowManager.hyprland =
    let
      border-size = config.theme.border-size;
      gaps-in = config.theme.gaps-in;
      gaps-out = config.theme.gaps-out;
      active-opacity = config.theme.active-opacity;
      inactive-opacity = config.theme.inactive-opacity;
      rounding = config.theme.rounding;
      blur = config.theme.blur;
    in
    {
      enable = true;
      xwayland.enable = true;
      systemd.enable = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;

      settings = {
        exec-once = [
          "dbus-update-activation-environment --systemd --all"
          "iio-hyprland"
          "clipse -listen"
          "walker --gapplication-service"
          "sherlock --daemonize"
          "1password --ozone-platform-hint=x11"
        ];

        animations = {
          enabled = "no";
        };

        monitor = [
          "eDP-1, 1920x1200@60, 0x0, 1, transform, 0"
          "desc:Huawei Technologies Co. Inc. XWU-CBA 0x00000001,2560x1440@143.97200,0x-1440,1"
          ",prefered,auto,1"
        ];

        workspace = [
          "1,monitor:DP-5"
          "2,monitor:DP-5"
          "3,monitor:DP-5"
          "4,monitor:eDP-1"
          "5,monitor:eDP-1"
          "6,monitor:eDP-1"
        ];

        windowrule = [
          "float, tag:modal"
          "pin, tag:modal"
          "center, tag:modal"
          "float,class:(clipse)"
          "size 622 652,class:(clipse)"

          "workspace 1, class:(zen)"
          "workspace 3, class:(org.wezfurlong.wezterm)"
          "workspace 4, class:(spotify_player)"
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
          # layout = "hy3";
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
          enable_swallow = true;
          swallow_regex = "^swallow$";
        };

        layerrule = [
          "noanim, launcher"
          "noanim, ^ags-.*"
        ];

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
      };
    };
}
