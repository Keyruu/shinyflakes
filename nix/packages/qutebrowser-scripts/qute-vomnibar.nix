{ pkgs }:
pkgs.writeShellApplication {
  name = "qute-vomnibar";
  runtimeInputs = with pkgs; [ vicinae jq sqlite yq-go ];
  excludeShellChecks = [ "SC2001" ];
  text = ''
    set +e

    if [ -z "$QUTE_FIFO" ]; then
      echo "This script must be run as a qutebrowser userscript" >&2
      exit 1
    fi

    MODE="''${1:-open}"

    ENTRIES=""

    echo "session-save default" >> "$QUTE_FIFO"
    sleep 0.1

    SESSION_FILE="$QUTE_DATA_DIR/sessions/default.yml"
    if [ -f "$SESSION_FILE" ]; then
      TABS=$(yq eval '
        .windows[].tabs | to_entries[] |
        "🗂️ " + ((.key + 1) | tostring) + ": " + .value.history[-1].title
      ' "$SESSION_FILE" 2>/dev/null)
      [ -n "$TABS" ] && ENTRIES="$TABS"
    fi

    if [ -f "$QUTE_DATA_DIR/history.sqlite" ]; then
      HISTORY=$(sqlite3 "$QUTE_DATA_DIR/history.sqlite" \
        "SELECT '🕐 ' || COALESCE(title, url) || char(9) || url FROM CompletionHistory ORDER BY last_atime DESC LIMIT 500" 2>/dev/null)
      [ -n "$HISTORY" ] && ENTRIES=$(printf "%s\n%s" "$ENTRIES" "$HISTORY")
    fi

    if [ -f "$QUTE_CONFIG_DIR/bookmarks/urls" ]; then
      BOOKMARKS=$(sed 's/^\(.*\) \(https\?:.*\)$/⭐ \1\t\2/' "$QUTE_CONFIG_DIR/bookmarks/urls" 2>/dev/null)
      [ -n "$BOOKMARKS" ] && ENTRIES=$(printf "%s\n%s" "$ENTRIES" "$BOOKMARKS")
    fi

    if [ -f "$QUTE_CONFIG_DIR/quickmarks" ]; then
      QUICKMARKS=$(awk '{name=$1; $1=""; sub(/^ /, ""); print "🔖 " name "\t" $0}' "$QUTE_CONFIG_DIR/quickmarks" 2>/dev/null)
      [ -n "$QUICKMARKS" ] && ENTRIES=$(printf "%s\n%s" "$ENTRIES" "$QUICKMARKS")
    fi

    SELECTION=$(echo "$ENTRIES" | grep -v '^$' | vicinae dmenu -p "open:")

    [ -z "$SELECTION" ] && exit 0

    DISPLAY_PART=$(echo "$SELECTION" | cut -f1)
    VALUE_PART=$(echo "$SELECTION" | cut -f2)

    if echo "$DISPLAY_PART" | grep -q '^🗂️'; then
      TAB_INDEX=$(echo "$DISPLAY_PART" | sed 's/^🗂️ \([0-9]*\):.*/\1/')
      echo "tab-focus $TAB_INDEX" >> "$QUTE_FIFO"
      exit 0
    fi

    if echo "$VALUE_PART" | grep -qE '^https?://'; then
      if [ "$MODE" = "tab" ]; then
        echo "open -t $VALUE_PART" >> "$QUTE_FIFO"
      else
        echo "open $VALUE_PART" >> "$QUTE_FIFO"
      fi
      exit 0
    fi

    QUERY=$(echo "$DISPLAY_PART" | sed 's/^\[.*\] //')

    if echo "$QUERY" | grep -qE '^https?://|^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/|$)'; then
      URL="$QUERY"
      echo "$URL" | grep -qE '^https?://' || URL="https://$URL"
      if [ "$MODE" = "tab" ]; then
        echo "open -t $URL" >> "$QUTE_FIFO"
      else
        echo "open $URL" >> "$QUTE_FIFO"
      fi
    else
      SEARCH_URL="https://kagi.com/search?q=$(echo "$QUERY" | jq -sRr @uri)"
      if [ "$MODE" = "tab" ]; then
        echo "open -t $SEARCH_URL" >> "$QUTE_FIFO"
      else
        echo "open $SEARCH_URL" >> "$QUTE_FIFO"
      fi
    fi
  '';
}
