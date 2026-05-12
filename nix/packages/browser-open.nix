{ pkgs }:
pkgs.writeShellApplication {
  name = "browser-open";
  runtimeInputs = with pkgs; [
    vicinae
    coreutils
    gnugrep
  ];
  text = ''
    URL="''${1:-}"

    declare -A BROWSERS=(
      [glide-personal]="glide-browser -P personal"
      [glide-work]="glide-browser -P work --new-instance"
      [librewolf]="librewolf"
      [firefox]="firefox"
      [qutebrowser-personal]="qute-profile launch personal"
      [qutebrowser-work]="qute-profile launch work"
    )

    RULES=(
      "meet\.google\.com|zoom\.us|teams\.microsoft\.com:glide-work"
      "jira\.|confluence\.|atlassian\.:glide-work"
    )

    pick_browser() {
      printf "%s\n" "''${!BROWSERS[@]}" | sort | vicinae dmenu -p "Open with:" -s "Browsers"
    }

    resolve_browser() {
      local url="$1"
      if [[ -n "$url" ]]; then
        for rule in "''${RULES[@]}"; do
          local pattern="''${rule%%:*}"
          local browser="''${rule##*:}"
          if echo "$url" | grep -qEi "$pattern"; then
            echo "$browser"
            return
          fi
        done
      fi
      pick_browser
    }

    CHOICE=$(resolve_browser "$URL")
    [[ -z "$CHOICE" ]] && exit 0

    CMD="''${BROWSERS[$CHOICE]:-}"
    if [[ -z "$CMD" ]]; then
      echo "Unknown browser: $CHOICE" >&2
      exit 1
    fi

    if [[ -n "$URL" ]]; then
      exec $CMD "$URL"
    else
      exec $CMD
    fi
  '';
}
