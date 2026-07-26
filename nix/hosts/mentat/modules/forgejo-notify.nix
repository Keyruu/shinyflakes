{ config, pkgs, ... }:
let
  forgejo-notify = pkgs.writeShellApplication {
    name = "forgejo-notify";
    runtimeInputs = with pkgs; [
      curl
      jq
      gotify-cli
    ];
    text = ''
      GOTIFY_TOKEN=$(cat ${config.sops.secrets.forgejoGotifyToken.path})
      export GOTIFY_TOKEN

      since_file="$STATE_DIRECTORY/since"
      now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

      # first run: skip backlog, only notify from now on
      if [ ! -f "$since_file" ]; then
        echo "$now" > "$since_file"
        exit 0
      fi

      since=$(cat "$since_file")
      token=$(cat ${config.sops.secrets.forgejoNotifyToken.path})

      resp=$(curl -fsS -G \
        -H "Authorization: token $token" \
        --data-urlencode "since=$since" \
        "https://git.lab.keyruu.de/api/v1/notifications")

      jq -c '.[]' <<< "$resp" | while read -r n; do
        repo=$(jq -r '.repository.full_name' <<< "$n")
        type=$(jq -r '.subject.type' <<< "$n")
        title=$(jq -r '.subject.title' <<< "$n")
        # subject.url is an API url; strip prefix to get the html url
        url=$(jq -r '.subject.url' <<< "$n" | sed 's|/api/v1/repos/|/|')
        gotify push \
          --url "https://notify.keyruu.de" \
          --title "$repo: $type" \
          --priority 4 \
          "$title
      $url"
      done

      # written last so a failed run retries the same window (dupes over losses)
      echo "$now" > "$since_file"
    '';
  };
in
{
  sops.secrets = {
    forgejoNotifyToken = { };
    forgejoGotifyToken = { };
  };

  systemd.services.forgejo-notify = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${forgejo-notify}/bin/forgejo-notify";
      StateDirectory = "forgejo-notify";
    };
  };

  systemd.timers.forgejo-notify = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "1m";
    };
  };
}
