{ config, pkgs, ... }:
let
  gotify-notify = pkgs.writeShellApplication {
    name = "gotify-notify";
    runtimeInputs = with pkgs; [
      websocat
      jq
      libnotify
    ];
    text = ''
      TOKEN=$(cat ${config.sops.secrets.gotifyDesktopToken.path})

      # TODO: maybe catch-up of messages missed while disconnected
      # fetch /message on start if that ever matters
      websocat --ping-interval 30 -H "X-Gotify-Key: $TOKEN" \
        wss://notify.keyruu.de/stream |
        while read -r msg; do
          urgency=$(jq -r 'if .priority >= 8 then "critical" else "normal" end' <<<"$msg")
          notify-send -u "$urgency" -a Gotify \
            "$(jq -r .title <<<"$msg")" "$(jq -r .message <<<"$msg")"
        done
    '';
  };
in
{
  sops.secrets.gotifyDesktopToken.owner = config.user.name;

  systemd.user.services.gotify-desktop = {
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
}
