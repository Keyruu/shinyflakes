{ lib, ... }:
let
  # niri IPC builders. Pure string composition, no module deps.
  # Workspace names mirror niri/default.nix — update both together.
  moveWs = ws: mon: i:
    "niri msg action move-workspace-to-monitor --reference ${ws} '${mon}' && niri msg action move-workspace-to-index --reference ${ws} ${toString i}";

  # Every monitor in the profile stacks here.
  moveAllToOne = mon: lib.concatStringsSep " && " [
    (moveWs "browse" mon 1)
    (moveWs "work" mon 2)
    (moveWs "social" mon 3)
  ];

  # Work goes to `workMon`; social goes to `socialMon`. Two distinct monitors.
  moveWorkspacesSplit = workMon: socialMon:
    lib.concatStringsSep " && " [
      (moveWs "browse" workMon 1)
      (moveWs "work" workMon 2)
      (moveWs "social" socialMon 1)
    ];

  # Outputs for one profile, in the order given. Position comes from
  # `positions` with "0,0" as the fallback (anchor).
  outputsFor = monitors: positions: names:
    map
      (name: monitors.${name} // { position = positions.${name} or "0,0"; })
      names;

  profile = name: outputs: exec: { profile = { inherit name outputs; inherit exec; }; };

  # Sort helper — stable alphabetical order so profile names don't churn
  # when the source list happens to be in a different order.
  sorted = xs: lib.sort (a: b: a < b) xs;

  nonEmptySubsets = xs:
    let
      # For each new element `x`, every subset either keeps it (and prepends x
      # to the subsets without it) or drops it (keeps the subset untouched).
      step = x: rest: rest ++ map (s: [ x ] ++ s) rest;
    in
    builtins.filter (s: s != [ ]) (lib.foldr step [ [ ] ] xs);

  buildProfiles = displays: monitors:
    let
      all = sorted (displays.primary ++ displays.secondaries);
      primaries = sorted displays.primary;
      secondaries = sorted displays.secondaries;
      inPrim = n: lib.elem n primaries;
      inSec = n: lib.elem n secondaries;

      # For each non-empty subset of monitors, build a profile. Name is the
      # sorted subset joined by "-". Workspace routing:
      #   - workMon   = first primary in the profile, else first monitor
      #   - socialMon = first secondary in the profile, else second monitor
      #     in alphabetical order, else workMon itself
      # Falls back to moveAllToOne when both collapse to the same monitor.
      mkExec = subset:
        let
          workMon =
            if lib.findFirst inPrim null subset != null
            then lib.findFirst inPrim null subset
            else lib.head subset;
          socialMon =
            if lib.findFirst inSec null subset != null
            then lib.findFirst inSec null subset
            else if lib.length subset >= 2
            then lib.head (lib.tail subset)
            else workMon;
        in
        if workMon == socialMon
        then [ (moveAllToOne (monitors.${workMon}.criteria)) ]
        else [ (moveWorkspacesSplit (monitors.${workMon}.criteria) (monitors.${socialMon}.criteria)) ];

      mkProfile = subset:
        profile
          (lib.concatStringsSep "-" subset)
          (outputsFor monitors displays.positions subset)
          (mkExec subset);
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
          terminal = false;
          categories = [ "Utility" ];
        };

        services.kanshi = {
          enable = true;
          systemdTarget = "graphical-session.target";
        } // lib.optionalAttrs (host.displays != null) {
          settings = buildProfiles host.displays config.monitors;
        };
      };
  };
}
