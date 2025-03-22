# - ## System
#- 
#- Usefull quick scripts
#-
#- - `menu` - Open wofi with drun mode. (wofi)
#- - `powermenu` - Open power dropdown menu. (wofi)
#- - `lock` - Lock the screen. (hyprlock)
{ pkgs, ... }:

let
  focusOrOpen = pkgs.writeShellScriptBin "focusOrOpen" 
    # bash
    ''
      #!/bin/sh

      execCommand=$1
      className=$2

      pid=$(hyprctl -j clients | jq -r "sort_by(.focusHistoryID) | .[] | select(.class == \"$className\") | .pid" | head -n 1)

      pgrep $1 && hyprctl dispatch focuswindow pid:$pid || $1
    '';

  powermenu = pkgs.writeShellScriptBin "powermenu"
    # bash
    ''
      if pgrep wofi; then
      	pkill wofi
      # if pgrep tofi; then
      #   pkill tofi
      else
        options=(
          "󰌾 Lock"
          "󰍃 Logout"
          " Suspend"
          "󰑐 Reboot"
          "󰿅 Shutdown"
        )

        selected=$(printf '%s\n' "''${options[@]}" | wofi -p " Powermenu" --dmenu)
        # selected=$(printf '%s\n' "''${options[@]}" | tofi --prompt-text "> ")
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
      fi
    '';

  quickmenu = pkgs.writeShellScriptBin "quickmenu"
    # bash
    ''
      if pgrep wofi; then
      	pkill wofi
      # if pgrep tofi; then
      #   pkill tofi
      else
        options=(
          "󰅶 Caffeine"
          "󰈊 Hyprpicker"
        )

        selected=$(printf '%s\n' "''${options[@]}" | wofi -p " Quickmenu" --dmenu)
        # selected=$(printf '%s\n' "''${options[@]}" | tofi --prompt-text "> ")
        selected=''${selected:2}

        case $selected in
          "Caffeine")
            caffeine
            ;;
          "Hyprpicker")
            sleep 0.2 && ${pkgs.hyprpicker}/bin/hyprpicker -a
            ;;
        esac
      fi
    '';

  lock = pkgs.writeShellScriptBin "lock"
    # bash
    ''
      ${pkgs.hyprlock}/bin/hyprlock
    '';

in { home.packages = [ focusOrOpen powermenu lock quickmenu ]; }
