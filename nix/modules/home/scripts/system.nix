{ pkgs, ... }:
let
  copyPasteShortcut = pkgs.writeShellApplication {
    name = "copyPasteShortcut";
    runtimeInputs = with pkgs; [
      wtype
      jq
      sway
      niri
    ];
    text = # bash
      ''
        action=$1
        shift
        terminal_classes=("$@")

        if [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
          active_class=$(niri msg -j windows | jq -r '.[] | select(.is_focused == true) | .app_id' | head -n 1)
        else
          active_class=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .app_id // .window_properties.class' | head -n 1)
        fi

        use_shift_modifier=false
        for class in "''${terminal_classes[@]}"; do
          if [ "$active_class" = "$class" ]; then
            use_shift_modifier=true
            break
          fi
        done

        case "$action" in
          copy)
            if [ "$use_shift_modifier" = true ]; then
              wtype -M ctrl -M shift -k c -m ctrl -m shift
            else
              wtype -M ctrl -k c -m ctrl
            fi
            ;;
          paste)
            if [ "$use_shift_modifier" = true ]; then
              wtype -M ctrl -M shift -k v -m ctrl -m shift
            else
              wtype -M ctrl -k v -m ctrl
            fi
            ;;
        esac
      '';
  };

  scratch = pkgs.writeShellApplication {
    name = "scratch";
    runtimeInputs = with pkgs; [
      jq
      sway
      wezterm
      gawk
    ];
    text = # bash
      ''
        monitor_resolution=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .rect | "\(.width) \(.height)"')
        monitor_width=$(echo "$monitor_resolution" | awk '{print $1}')
        monitor_height=$(echo "$monitor_resolution" | awk '{print $2}')

        width=$((monitor_width * 88 / 100))
        height=$((monitor_height * 92 / 100))

        if ! swaymsg '[app_id="^scratchpad$"] scratchpad show, resize set width '$width' px height '$height' px'; then
          exec wezterm start --class scratchpad
        fi
      '';
  };

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
    copyPasteShortcut
    scratch
    scratch-niri
  ];
}
