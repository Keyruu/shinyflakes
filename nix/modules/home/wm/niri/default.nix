{
  inputs,
  pkgs,
  perSystem,
  ...
}:
{
  imports = [
    inputs.niri.homeModules.niri
  ];

  home.packages = with pkgs; [
    nirius
    iio-niri
    xwayland-satellite
  ];

  programs.niri = {
    enable = true;
    package = perSystem.niri.niri-unstable;

    config = # kdl
      ''
        xwayland-satellite {}

        spawn-at-startup "niriusd"
        spawn-at-startup "iio-niri" "--monitor" "eDP-1"
        spawn-at-startup "clipse" "-listen"
        spawn-at-startup "1password" "--ozone-platform-hint=wayland" "--silent"
        spawn-at-startup "distrobox" "enter" "mdm" "--" "exit"
        spawn-at-startup "${pkgs.dbus}/bin/dbus-update-activation-environment" "--systemd" "--all"

        cursor {
            xcursor-size 20
            xcursor-theme "phinger-cursors-light"
        }

        prefer-no-csd
        hotkey-overlay { skip-at-startup false; }
        screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

        animations {}

        debug {
            honor-xdg-activation-with-invalid-serial
        }

        workspace "browse"
        workspace "work"
        workspace "social"

        include "${./input.kdl}"
        include "${./outputs.kdl}"
        include "${./layout.kdl}"
        include "${./window-rules.kdl}"
        include "${./binds.kdl}"
        include "${./alt-tab.kdl}"
      '';
  };
}
