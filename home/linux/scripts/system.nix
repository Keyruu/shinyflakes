{ lib, pkgs, ... }:
let
  focusOrOpen =
    pkgs.writeShellScriptBin "focusOrOpen" # bash
      ''
        #!/bin/sh

        execCommand=$1
        className=$2

        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] || pgrep -x "Hyprland" > /dev/null; then
          address=$(hyprctl -j clients | jq -r "sort_by( .focusHistoryID) | .[] | select(.class == \"$className\") | .address" | head -n 1)

          if [ -n "$address" ]; then
            hyprctl dispatch focuswindow address:$address
          else
            $1
          fi
        elif [ "$XDG_CURRENT_DESKTOP" = "sway" ] || pgrep -x "sway" > /dev/null; then
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
        else
          # Fallback - just execute the command
          $1
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

  powermenu =
    pkgs.writeShellScriptBin "powermenu"
      # bash
      ''
        options=(
          "󰌾 Lock"
          "󰍃 Logout"
          " Suspend"
          "󰑐 Reboot"
          "󰿅 Shutdown"
        )

        selected=$(printf '%s\n' "''${options[@]}" | walker --dmenu)
        selected=''${selected:2}

        case $selected in
          "Lock")
            ${pkgs.hyprlock}/bin/hyprlock
            ;;
          "Logout")
            hyprctl dispatch exit
            ;;
          "Suspend")
            systemctl suspend
            ;;
          "Reboot")
            systemctl reboot
            ;;
          "Shutdown")
            systemctl poweroff
            ;;
        esac
      '';

  quickmenu =
    pkgs.writeShellScriptBin "quickmenu"
      # bash
      ''
        options=(
          "󰅶 Caffeine"
          "󰈊 Hyprpicker"
        )

        selected=$(printf '%s\n' "''${options[@]}" | fuzzel --dmenu)
        selected=''${selected:2}

        case $selected in
          "Caffeine")
            caffeine
            ;;
          "Hyprpicker")
            sleep 0.2 && ${pkgs.hyprpicker}/bin/hyprpicker -a
            ;;
        esac
      '';

  lock =
    pkgs.writeShellScriptBin "lock"
      # bash
      ''
        ${pkgs.hyprlock}/bin/hyprlock
      '';

  waybar-fullscreen =
    pkgs.writeShellScriptBin "waybar-fullscreen"
      # bash
      ''
        # Detect which window manager is running
        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] || pgrep -x "Hyprland" > /dev/null; then
          # Hyprland
          is_fullscreen=$(hyprctl -j activewindow | jq -r '.fullscreen')

          if [ "$is_fullscreen" -eq 1 ]; then
            echo "󰊓"
          fi
        elif [ "$XDG_CURRENT_DESKTOP" = "sway" ] || pgrep -x "sway" > /dev/null; then
          # Sway
          is_fullscreen=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .fullscreen_mode')

          if [ "$is_fullscreen" -eq 1 ]; then
            echo "󰊓"
          fi
        fi
      '';

in
{
  home.packages = [
    focusOrOpen
    copyPasteShortcut
    powermenu
    lock
    quickmenu
    waybar-fullscreen
  ];
}
