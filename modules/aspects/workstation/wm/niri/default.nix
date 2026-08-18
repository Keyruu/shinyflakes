{ inputs, lib, ... }:
let
  # kdl output block per monitor from the registry + `displays` layout.
  # Used as a transient default at niri startup; kanshi overrides once a
  # profile applies.
  mkOutputBlock = name: displays: monitors:
    let
      mon = monitors.${name};
      pos = displays.positions.${name} or "0,0";
      parts = lib.splitString "," pos;
      x = builtins.elemAt parts 0;
      y = builtins.elemAt parts 1;
      px = "x=" + x;
      py = "y=" + y;
      # niri rejects the @NNHz suffix in `mode`; kanshi accepts both.
      mode = lib.removeSuffix "Hz" mon.mode;
    in
    ''
      output "${mon.criteria}" {
          mode "${mode}"
          scale ${toString mon.scale}
          position ${px} ${py}
      }
    '';

  mkOutputBlocks = displays: monitors:
    lib.concatMapStringsSep "\n"
      (n: mkOutputBlock n displays monitors)
      (displays.primary ++ displays.secondaries);
in
{
  den.aspects.workstation.wm.niri = { host, ... }: {
    nixos =
      {
        pkgs,
        inputs',
        lib,
        ...
      }:
      let
        niri = inputs'.niri.packages.niri-unstable;
      in
      {
        services.xserver.enable = lib.mkForce false;

        services.displayManager.sessionPackages = [
          niri
        ];

        programs.niri = {
          enable = true;
          package = niri;
          useNautilus = true;
        };

        xdg.portal = {
          enable = true;
          wlr.enable = false;
          config = {
            niri = {
              "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
              "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
              "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
            };
          };
          extraPortals = with pkgs; [
            xdg-desktop-portal-gtk
            xdg-desktop-portal-gnome
          ];
        };
      };

    homeManager =
      {
        pkgs,
        inputs',
        config,
        ...
      }:
      {
        imports = [
          inputs.niri.homeModules.niri
        ];

        home.pointerCursor = {
          enable = true;
          package = pkgs.phinger-cursors;
          name = "phinger-cursors-light";
          size = 20;
          gtk.enable = true;
        };

        home.packages = with pkgs; [
          nirius
          iio-niri
          xwayland-satellite
        ];

        programs.niri = {
          enable = true;
          package = inputs'.niri.packages.niri-unstable;

          config = # kdl
            ''
              ${lib.optionalString (host.displays != null)
                (mkOutputBlocks host.displays config.monitors)}

              xwayland-satellite {}

              spawn-at-startup "niriusd"
              spawn-at-startup "iio-niri" "--monitor" "eDP-1"
              spawn-at-startup "clipse" "-listen"
              spawn-at-startup "1password" "--ozone-platform-hint=wayland" "--silent"
              spawn-at-startup "distrobox" "enter" "mdm" "--" "exit"
              spawn-at-startup "${pkgs.dbus}/bin/dbus-update-activation-environment" "--systemd" "--all"
              spawn-at-startup "handy"

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
              include "${./layout.kdl}"
              include "${./window-rules.kdl}"
              include "${./binds.kdl}"
              include "${./alt-tab.kdl}"
            '';
        };
      };
  };
}
