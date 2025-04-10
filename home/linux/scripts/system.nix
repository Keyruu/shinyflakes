# - ## System
#- 
#- Usefull quick scripts
#-
#- - `menu` - Open wofi with drun mode. (wofi)
#- - `powermenu` - Open power dropdown menu. (wofi)
#- - `lock` - Lock the screen. (hyprlock)
{ pkgs, ... }:

let
  focusOrOpen = pkgs.writeShellScriptBin "focusOrOpen" /* bash */ ''
    #!/bin/sh

    execCommand=$1
    className=$2

    address=$(hyprctl -j clients | jq -r "sort_by( .focusHistoryID) | .[] | select(.class == \"$className\") | .address" | head -n 1)

    if [ -n "$address" ]; then
      hyprctl dispatch focuswindow address:$address
    else
      $1
    fi
  '';

  copyPasteShortcut = pkgs.writeShellScriptBin "copyPasteShortcut" /* bash */ ''
    #!/bin/sh
    
    action=$1
    terminal_class=$2

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
  '';

  powermenu = pkgs.writeShellScriptBin "powermenu"
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

  quickmenu = pkgs.writeShellScriptBin "quickmenu"
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

  lock = pkgs.writeShellScriptBin "lock"
    # bash
    ''
      ${pkgs.hyprlock}/bin/hyprlock
    '';

in { home.packages = [ focusOrOpen copyPasteShortcut powermenu lock quickmenu ]; }
