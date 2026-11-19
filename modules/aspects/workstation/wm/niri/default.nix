{ inputs, lib, ... }:
let
  # kdl output block per monitor from the registry + `displays` layout.
  # Used as a transient default at niri startup; kanshi overrides once a
  # profile applies.
  mkOutputBlock =
    name: displays: monitors:
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

  mkOutputBlocks =
    displays: monitors:
    lib.concatMapStringsSep "\n" (n: mkOutputBlock n displays monitors) (
      displays.primary ++ displays.secondaries
    );
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

        # mkDefault so a host/aspect (e.g. mango) can mkForce a different
        # greetd session command
        services.greetd.settings = {
          default_session.command = lib.mkDefault "${niri}/bin/niri-session";
          initial_session.command = lib.mkDefault "${niri}/bin/niri-session";
        };

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
      let
        mirror = pkgs.writeShellApplication {
          name = "mirror";
          runtimeInputs = [
            pkgs.wl-mirror
            inputs'.niri.packages.niri-unstable
            pkgs.jq
          ];
          text = ''
            focused=$(niri msg --json focused-output | jq -r .name)
            other=$(niri msg --json outputs | jq -r --arg f "$focused" '.[] | select(.name != $f) | .name' | head -n1)
            exec wl-mirror --fullscreen-output "$focused" "$other"
          '';
        };
        # scratch-niri <app_id> <cmd...>: toggle a nirius scratchpad, spawning it
        # if missing. Restored from before the mango migration (6d950db8f).
        scratch-niri = pkgs.writeShellApplication {
          name = "scratch-niri";
          runtimeInputs = [
            pkgs.jq
            pkgs.nirius
            pkgs.coreutils
            inputs'.niri.packages.niri-unstable
          ];
          text = # bash
            ''
              app_id=$1
              shift
              spawn_cmd=("$@")

              find_window() { niri msg -j windows | jq -r --arg a "$app_id" 'first(.[] | select(.app_id == $a) | .id) // empty'; }
              window_id=$(find_window)

              if [ -z "$window_id" ]; then
                # spawn via niri so the app gets niri's environment (fish), not ours
                niri msg action spawn -- "''${spawn_cmd[@]}"
                # poll: cold-start can exceed any fixed sleep,
                # and nirius is a no-op when no window matches yet
                for _ in $(seq 1 50); do
                  window_id=$(find_window)
                  [ -n "$window_id" ] && break
                  sleep 0.1
                done
                # move window onto scratchpad workspace + mark it as scratchpad,
                # so scratchpad-show below (and on next invocations) can toggle cleanly
                nirius scratchpad-toggle -a "^$app_id$"
              fi

              # niriusd forgets scratchpads when it restarts: re-register, then show
              nirius scratchpad-show -a "^$app_id$" || {
                nirius scratchpad-toggle -a "^$app_id$"
                nirius scratchpad-show -a "^$app_id$"
              }
              niri msg action set-window-height --id "$window_id" 88%
              niri msg action set-window-width --id "$window_id" 88%
            '';
        };
      in
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
          xwayland-satellite
          wl-mirror
          nirius
          scratch-niri
        ];

        # Bound to niri.service (not graphical-session.target) so it never
        # starts under mango, and restarts if it crashes.
        systemd.user.services.niriusd = {
          Unit = {
            Description = "nirius daemon";
            After = [ "niri.service" ];
            PartOf = [ "niri.service" ];
          };
          Service = {
            ExecStart = "${pkgs.nirius}/bin/niriusd";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "niri.service" ];
        };

        xdg.desktopEntries.mirror = {
          name = "Mirror Screen";
          exec = "${mirror}/bin/mirror";
          categories = [ "Utility" ];
          icon = "video-display";
        };

        programs.niri = {
          enable = true;
          package = inputs'.niri.packages.niri-unstable;

          config = # kdl
            ''
              ${lib.optionalString (host.displays != null) (mkOutputBlocks host.displays config.monitors)}

              xwayland-satellite {}

              spawn-at-startup "${pkgs.dbus}/bin/dbus-update-activation-environment" "--systemd" "--all"
              spawn-at-startup "clipse" "-listen"
              spawn-at-startup "1password" "--ozone-platform-hint=wayland" "--silent"

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

              include optional=true "dms/layout.kdl"
              include optional=true "dms/colors.kdl"
              include optional=true "dms/cursor.kdl"
              include optional=true "dms/wpblur.kdl"
            '';
        };
      };
  };
}
