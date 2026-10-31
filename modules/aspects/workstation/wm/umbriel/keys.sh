#!/usr/bin/env bash
set -euo pipefail

# Keybind actions cannot branch on the focused window's scratchpad/tab state.
state=$(umbriel focused-window --json 2>/dev/null) || exit 0

case "${1:-}" in
  left|right)
    if [ "$(jq -r '.tabbed // false' <<<"$state")" = true ]; then
      if [ "$1" = left ]; then
        exec umbriel msg column-focus-tab-previous
      fi
      exec umbriel msg column-focus-tab-next
    fi
    exec umbriel msg "window-focus-$1"
    ;;
  close)
    scratchpad=$(jq -r '.scratchpad // empty' <<<"$state")
    if [ -n "$scratchpad" ]; then
      exec umbriel msg scratchpad-toggle "$scratchpad"
    fi
    exec umbriel msg window-close
    ;;
  *)
    printf 'usage: umbriel-key [left|right|close]\n' >&2
    exit 2
    ;;
esac
