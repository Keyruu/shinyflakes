{ lib, ... }:
let
  # Workspace placement for one profile: "<ws> '<criteria>' <index>" triples
  # consumed by the niri-place-ws helper below. Workspace names mirror
  # niri/default.nix — update both together.
  place = ws: mon: i: "${ws} '${mon}' ${toString i}";

  # Every monitor in the profile stacks here.
  allToOne = mon: [
    (place "browse" mon 1)
    (place "work" mon 2)
    (place "social" mon 3)
  ];

  # Work goes to `workMon`; social goes to `socialMon`. Two distinct monitors.
  split = workMon: socialMon: [
    (place "browse" workMon 1)
    (place "work" workMon 2)
    (place "social" socialMon 1)
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

  buildProfiles = placeWs: displays: monitors:
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
        [
          (lib.concatStringsSep " " (
            [ placeWs ]
            ++ (
              if workMon == socialMon then
                allToOne monitors.${workMon}.criteria
              else
                split monitors.${workMon}.criteria monitors.${socialMon}.criteria
            )
          ))
        ];

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
      let
        # Moves named niri workspaces onto the outputs of the applied profile.
        # Criteria may be kanshi globs, so resolve them to a niri output name.
        # Retries cover outputs that kanshi sees before niri does (resume).
        # No-op outside niri (e.g. mango).
        placeWs = lib.getExe (
          pkgs.writeShellApplication {
            name = "niri-place-ws";
            runtimeInputs = [ pkgs.jq ];
            text = ''
              [ -n "''${NIRI_SOCKET:-}" ] || exit 0
              resolve() {
                local outputs name desc
                outputs=$(niri msg --json outputs | jq -r '.[] | [.name, "\(.make) \(.model) \(.serial // "Unknown")"] | @tsv') || return 0
                while IFS=$'\t' read -r name desc; do
                  # shellcheck disable=SC2053 # unquoted RHS: glob match is intended
                  if [[ $name == $1 || $desc == $1 ]]; then echo "$name"; return; fi
                done <<<"$outputs"
              }
              while [ $# -ge 3 ]; do
                ws=$1 crit=$2 idx=$3
                shift 3
                out=""
                for _ in 1 2 3 4 5 6 7 8 9 10; do
                  out=$(resolve "$crit")
                  [ -n "$out" ] && break
                  sleep 0.5
                done
                if [ -z "$out" ]; then echo "niri-place-ws: no output matches '$crit'" >&2; continue; fi
                niri msg action move-workspace-to-monitor --reference "$ws" "$out" || true
                niri msg action move-workspace-to-index --reference "$ws" "$idx" || true
              done
            '';
          }
        );
      in
      {
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
        } // lib.optionalAttrs (host.displays != null) {
          settings = buildProfiles placeWs host.displays config.monitors;
        };
      };
  };
}
