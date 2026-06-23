{ pkgs, ... }:
let
  scratch-niri = pkgs.writeShellApplication {
    name = "scratch-niri";
    runtimeInputs = with pkgs; [
      jq
      niri
      nirius
      coreutils
    ];
    text = # bash
      ''
        app_id=$1
        shift
        spawn_cmd=("$@")

        window_id=$(niri msg -j windows | jq -r ".[] | select(.app_id == \"$app_id\") | .id")

        if [ -z "$window_id" ]; then
          niri msg action spawn -- "''${spawn_cmd[@]}"
          # poll: cold-start of footclient etc. can exceed any fixed sleep,
          # and nirius is a no-op when no window matches yet
          for _ in $(seq 1 50); do
            window_id=$(niri msg -j windows | jq -r ".[] | select(.app_id == \"$app_id\") | .id")
            [ -n "$window_id" ] && break
            sleep 0.1
          done
          # move window onto scratchpad workspace + mark it as scratchpad,
          # so scratchpad-show below (and on next invocations) can toggle cleanly
          nirius scratchpad-toggle -a "$app_id"
        fi

        nirius scratchpad-show -a "$app_id"
        niri msg action set-window-height --id "$window_id" 88%
        niri msg action set-window-width --id "$window_id" 88%
      '';
  };
in
{
  home.packages = [
    scratch-niri
  ];
}
