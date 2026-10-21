{ lib, ... }:
let
  # Outputs for one profile, in the order given. Position comes from
  # `positions` with "0,0" as the fallback (anchor).
  outputsFor =
    monitors: positions: names:
    map (name: monitors.${name} // { position = positions.${name} or "0,0"; }) names;

  profile = name: outputs: { profile = { inherit name outputs; }; };

  # Sort helper — stable alphabetical order so profile names don't churn
  # when the source list happens to be in a different order.
  sorted = xs: lib.sort (a: b: a < b) xs;

  nonEmptySubsets =
    xs:
    let
      # For each new element `x`, every subset either keeps it (and prepends x
      # to the subsets without it) or drops it (keeps the subset untouched).
      step = x: rest: rest ++ map (s: [ x ] ++ s) rest;
    in
    builtins.filter (s: s != [ ]) (lib.foldr step [ [ ] ] xs);

  buildProfiles =
    displays: monitors:
    let
      all = sorted (displays.primary ++ displays.secondaries);
      mkProfile =
        subset: profile (lib.concatStringsSep "-" subset) (outputsFor monitors displays.positions subset);
    in
    map mkProfile (nonEmptySubsets all);
in
{
  den.aspects.workstation.wm.kanshi = { host, ... }: {
    homeManager =
      { pkgs, config, ... }:
      {
        # Reload kanshi after resume from suspend/hibernate. Without this,
        # monitor hotplug events on wake are sometimes missed and profiles
        # don't re-apply until the cable is replugged.
        systemd.user.services.kanshi-resume = {
          Unit = {
            Description = "Reload kanshi after resume";
            After = [
              "sleep.target"
              "suspend.target"
              "hibernate.target"
              "hybrid-sleep.target"
              "suspend-then-hibernate.target"
            ];
            Requisite = [ "kanshi.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.kanshi}/bin/kanshictl reload";
          };
          Install.WantedBy = [
            "sleep.target"
            "suspend.target"
            "hibernate.target"
            "hybrid-sleep.target"
            "suspend-then-hibernate.target"
          ];
        };

        xdg.desktopEntries.kanshi-reload = {
          name = "Reload Kanshi";
          comment = "Re-evaluate kanshi profiles";
          exec = "${pkgs.kanshi}/bin/kanshictl reload";
          icon = "preferences-desktop-display";
          categories = [ "Utility" ];
        };

        services.kanshi = {
          enable = true;
          systemdTarget = "graphical-session.target";
        }
        // lib.optionalAttrs (host.displays != null) {
          settings = buildProfiles host.displays config.monitors;
        };
      };
  };
}
