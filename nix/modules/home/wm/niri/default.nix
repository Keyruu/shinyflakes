{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inputKdl = import ./input.nix { inherit pkgs lib; };
  outputsKdl = import ./outputs.nix { inherit pkgs lib; };
  layoutKdl = import ./layout.nix { inherit pkgs lib; };
  workspacesKdl = import ./workspaces.nix { inherit pkgs lib; };
  windowRulesKdl = import ./window-rules.nix { inherit pkgs lib; };
  bindsKdl = import ./binds.nix { inherit pkgs lib; };
  altTabKdl = import ./alt-tab.nix { inherit pkgs lib; };

  wallpaper = ../../themes/dark-bg.jpg;
in
{
  imports = [
    inputs.niri.homeModules.niri
  ];

  home.packages = with pkgs; [
    nirius
    iio-niri
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;

    config = ''
      xwayland-satellite {
          path "${lib.getExe pkgs.xwayland-satellite}"
      }

      spawn-at-startup "niriusd"
      spawn-at-startup "${lib.getExe pkgs.iio-niri}" "--monitor" "eDP-1"
      spawn-at-startup "swaybg" "-i" "${wallpaper}" "-m" "fill"
      spawn-at-startup "clipse" "-listen"
      spawn-at-startup "1password" "--ozone-platform-hint=wayland" "--silent"
      spawn-at-startup "tailscale" "systray"
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

      ${inputKdl}
      ${outputsKdl}
      ${layoutKdl}
      ${workspacesKdl}
      ${windowRulesKdl}
      ${bindsKdl}
      ${altTabKdl}
    '';
  };
}
