{ ... }:
{
  den.aspects.workstation.gotify-desktop = {
    nixos = { user, config, pkgs, ... }: {
      sops.secrets.gotifyDesktopToken.owner = user.userName;

      systemd.user.services.gotify-desktop = let
        gotify-notify = pkgs.writeShellApplication {
          name = "gotify-notify";
          runtimeInputs = with pkgs; [
            websocat
            jq
            libnotify
            curl
          ];
          text = ''
            TOKEN=$(cat ${config.sops.secrets.gotifyDesktopToken.path})
            BASE=https://notify.keyruu.de

            ICON_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/gotify-notify"
            mkdir -p "$ICON_DIR"

            fetch_icons() {
              curl -sf -H "X-Gotify-Key: $TOKEN" "$BASE/application" |
                jq -r '.[] | "\(.id) \(.image)"' |
                while read -r id image; do
                  [ -f "$ICON_DIR/$id" ] || curl -sf -o "$ICON_DIR/$id" "$BASE/$image" || true
                done
            }
            fetch_icons

            # TODO: maybe catch-up of messages missed while disconnected
            # fetch /message on start if that ever matters
            # -H is multi-value and would eat the URL; = binds a single value.
            # -n: service stdin is /dev/null; without it EOF closes the socket immediately
            websocat -n --ping-interval 30 -H="X-Gotify-Key: $TOKEN" \
              wss://notify.keyruu.de/stream |
              while read -r msg; do
                urgency=$(jq -r 'if .priority >= 8 then "critical" else "normal" end' <<<"$msg")
                icon="$ICON_DIR/$(jq -r .appid <<<"$msg")"
                # unknown app -> refresh cache once (new app since startup)
                [ -f "$icon" ] || fetch_icons
                icon_args=()
                [ -f "$icon" ] && icon_args=(-i "$icon")
                notify-send -u "$urgency" -a Gotify \
                  "''${icon_args[@]}" \
                  "$(jq -r .title <<<"$msg")" "$(jq -r .message <<<"$msg")"
              done
          '';
        };
      in {
        description = "Gotify desktop notifications";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${gotify-notify}/bin/gotify-notify";
          # websocat exits on connection loss — always reconnect
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
  };
}