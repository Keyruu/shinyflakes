{ lib, pkgs, ... }:
let
  focusOrOpen =
    pkgs.writeShellScriptBin "focusOrOpen" # bash
      ''
        #!/bin/sh

        execCommand=$1
        className=$2

        # Sway - find the most recently focused window using focus arrays
        window_id=$(swaymsg -r -t get_tree | jq -r "
          [.. | select(.app_id? == \"$className\" or .window_properties.class? == \"$className\")] as \$windows |
          if (\$windows | length) == 0 then empty
          elif (\$windows | length) == 1 then \$windows[0].id
          else
            # Find containers with focus arrays that contain our window IDs
            [.. | select(.focus? and (.focus | length) > 0)] as \$containers |
            \$containers[] |
            .focus[] as \$focused_id |
            \$windows[] |
            select(.id == \$focused_id) |
            .id
          end | tostring" | head -n 1)

        if [ -n "$window_id" ] && [ "$window_id" != "null" ]; then
          swaymsg "[con_id=$window_id] focus"
        else
          swaymsg exec -- "$1"
        fi
      '';

  copyPasteShortcut =
    pkgs.writeShellScriptBin "copyPasteShortcut" # bash
      ''
        #!/bin/sh

        action=$1
        shift
        terminal_classes="$@"

        # Sway - get focused window info
        active_class=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .app_id // .window_properties.class' | head -n 1)

        # Check if active_class matches any of the provided terminal classes
        use_shift_modifier=false
        for class in $terminal_classes; do
            if [ "$active_class" = "$class" ]; then
                use_shift_modifier=true
                break
            fi
        done

        case "$action" in
            copy)
                if [ "$use_shift_modifier" = true ]; then
                    ${lib.getExe pkgs.wtype} -M ctrl -M shift -k c -m ctrl -m shift
                else
                    ${lib.getExe pkgs.wtype} -M ctrl -k c -m ctrl
                fi
                ;;
            paste)
                if [ "$use_shift_modifier" = true ]; then
                    ${lib.getExe pkgs.wtype} -M ctrl -M shift -k v -m ctrl -m shift
                else
                    ${lib.getExe pkgs.wtype} -M ctrl -k v -m ctrl
                fi
                ;;
        esac
      '';

  scratch =
    pkgs.writeShellScriptBin "scratch" # bash
      ''
        #!/bin/bash

        # Get the current focused monitor's geometry (resolution)
        monitor_resolution=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .rect | "\(.width) \(.height)"')

        # Extract width and height from the geometry
        monitor_width=$(echo $monitor_resolution | awk '{print $1}')
        monitor_height=$(echo $monitor_resolution | awk '{print $2}')

        # Calculate desired size (e.g., 88% width, 92% height)
        width=$((monitor_width * 88 / 100))
        height=$((monitor_height * 92 / 100))

        if ! swaymsg '[app_id="^scratchpad$"] scratchpad show, resize set width '$width' px height '$height' px'; then
          # If the scratchpad doesn't exist, launch it
          exec foot --app-id scratchpad
        fi
      '';

  type-umlaut =
    pkgs.writeShellScriptBin "type-umlaut" # bash
      ''
        #!/bin/bash

        char="$1"
        wl-paste > /tmp/clipboard-backup-$$ 2>/dev/null || touch /tmp/clipboard-backup-$$
        echo -n "$char" | wl-copy
        copyPasteShortcut paste org.wezfurlong.wezterm dev.zed.Zed

        wl-copy < /tmp/clipboard-backup-$$
        rm -f /tmp/clipboard-backup-$$
      '';
in
{
  home.packages = [
    focusOrOpen
    copyPasteShortcut
    scratch
    type-umlaut
  ];
}
