{ pkgs, ... }:
let
  notif =
    pkgs.writeShellScriptBin "notif" # bash
      ''
        # Shell script to send custom notifications
        # Usage: notif "sender_id" "message" ["description"]
        NOTIF_FOLDER="/tmp/notif"
        sender_id=$1 # To overwrite existing notifications
        title=$2
        description=$3

        [[ -d "$NOTIF_FOLDER" ]] || mkdir $NOTIF_FOLDER
        [[ -f "$NOTIF_FOLDER/$sender_id" ]] || (echo "0" > "$NOTIF_FOLDER/$sender_id")

        old_notification_id=$(cat "$NOTIF_FOLDER/$sender_id")
        [[ -z "$old_notification_id" ]] && old_notification_id=0

         ${pkgs.libnotify}/bin/notify-send \
        --replace-id="$old_notification_id" --print-id \
        --app-name="$sender_id" \
        "$title" \
        "$description" \
        > "$NOTIF_FOLDER/$sender_id"
      '';

  waybar-dunst-monitor = pkgs.writeShellScriptBin "waybar-dunst-monitor" ''
    #!/bin/sh
    set -euo pipefail

    PATH=${pkgs.dunst}/bin:$PATH

    # --- Icons --- (Adjust to your preference/NerdFont)
    ICON_ACTIVE_IDLE='󰂚'      # Bell icon (no notifications)
    ICON_ACTIVE_WAITING='󱅫'   # Bell icon (notifications waiting)
    ICON_PAUSED='󰂛'         # Pause icon

    # --- Function to query Dunst and print Waybar JSON ---
    update_output() {
      COUNT=$(dunstctl count waiting)
      PAUSED=$(dunstctl is-paused) # Outputs "true" or "false"

      if [[ "$PAUSED" == "true" ]]; then
        CLASS="paused"
        if [[ "$COUNT" -gt 0 ]]; then
          TEXT="$ICON_PAUSED $COUNT"
          TOOLTIP="Paused ($COUNT waiting)"
        else
          TEXT="$ICON_PAUSED"
          TOOLTIP="Paused (0 waiting)"
        fi
      else # Not paused (active)
        if [[ "$COUNT" -gt 0 ]]; then
          CLASS="active-waiting"
          TEXT="$ICON_ACTIVE_WAITING $COUNT"
          TOOLTIP="Active ($COUNT waiting)"
        else
          CLASS="active-idle"
          TEXT="$ICON_ACTIVE_IDLE"
          TOOLTIP="Active (0 waiting)"
        fi
      fi

      # Output JSON for Waybar
      printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS" | jq --unbuffered --compact-output . # Ensure valid JSON, handle special chars
      # If jq gives issues or isn't desired, carefully escape quotes in printf:
      # printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$(echo $TEXT | sed 's/"/\\"/g')" "$(echo $TOOLTIP | sed 's/"/\\"/g')" "$CLASS"
    }

    # --- Initial output ---
    update_output

    # --- Monitor D-Bus for changes and update ---
    # Using exec to replace the shell process with dbus-monitor
    exec ${pkgs.dbus}/bin/dbus-monitor --profile "path='/org/freedesktop/Notifications',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" | \
    while read -r _; do
      # When a signal is received, refresh the output
      update_output
    done
  '';

in
{
  home.packages = [
    pkgs.libnotify
    notif
    waybar-dunst-monitor
  ];
}
