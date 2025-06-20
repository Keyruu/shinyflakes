# - ## System
#-
#- Usefull quick scripts
#-
#- - `menu` - Open wofi with drun mode. (wofi)
#- - `powermenu` - Open power dropdown menu. (wofi)
#- - `lock` - Lock the screen. (hyprlock)
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
          # Sway - look for marked window first, then any window of the class
          mark_name="_last_$className"
          
          if swaymsg "[con_mark=\"$mark_name\"] focus" 2>/dev/null; then
            :
          else
            # No marked window or mark doesn't exist, find any window of this class
            window_id=$(swaymsg -r -t get_tree | jq -r ".. | select(.app_id? == \"$className\" or .window_properties.class? == \"$className\") | .id" | head -n 1)
            
            if [ -n "$window_id" ] && [ "$window_id" != "null" ]; then
              # Focus the window and mark it for future use
              swaymsg "[con_id=$window_id] focus, mark --add \"$mark_name\""
            else
              # No existing window, launch new one
              swaymsg exec -- "$1"
            fi
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
        terminal_class=$2

        # Detect which window manager is running
        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] || pgrep -x "Hyprland" > /dev/null; then
          # Hyprland
          active_class=$(hyprctl activewindow -j | jq -r '.class')
          
          case "$action" in
              copy)
                  key="C"
                  ;;
              paste)
                  key="V"
                  ;;
          esac

          if [ "$active_class" = "$terminal_class" ]; then
              shortcut="CTRL_SHIFT,$key,"
          else
              shortcut="CTRL,$key,"
          fi

          hyprctl dispatch sendshortcut "$shortcut"
        elif [ "$XDG_CURRENT_DESKTOP" = "sway" ] || pgrep -x "sway" > /dev/null; then
          # Sway - get focused window info
          active_class=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .app_id // .window_properties.class' | head -n 1)
          
          case "$action" in
              copy)
                  if [ "$active_class" = "$terminal_class" ]; then
                      ${lib.getExe pkgs.wtype} -M ctrl -M shift -k c -m ctrl -m shift
                  else
                      ${lib.getExe pkgs.wtype} -M ctrl -k c -m ctrl
                  fi
                  ;;
              paste)
                  if [ "$active_class" = "$terminal_class" ]; then
                      ${lib.getExe pkgs.wtype} -M ctrl -M shift -k v -m ctrl -m shift
                  else
                      ${lib.getExe pkgs.wtype} -M ctrl -k v -m ctrl
                  fi
                  ;;
          esac
        fi
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

  sway-focus-tracker =
    pkgs.writeShellScriptBin "sway-focus-tracker"
      # bash
      ''
        #!/bin/sh
        # Track focus changes in Sway and mark windows for focusOrOpen script

        swaymsg -m -r -t subscribe '["window"]' | \
          jq --unbuffered -r 'select(.change == "focus") | "\(.container.app_id // .container.window_properties.class // "unknown"):\(.container.id)"' | \
          while IFS=: read -r app_id window_id; do
            if [ -n "$app_id" ] && [ "$app_id" != "null" ] && [ "$app_id" != "unknown" ]; then
              mark_name="_last_$app_id"
              # Remove old mark for this app and add new one
              swaymsg "[con_mark=\"$mark_name\"] unmark \"$mark_name\"" 2>/dev/null
              swaymsg "[con_id=$window_id] mark --add \"$mark_name\"" 2>/dev/null
            fi
          done
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
    sway-focus-tracker
  ];
}
