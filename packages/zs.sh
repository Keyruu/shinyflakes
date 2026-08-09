# fzf picker over zellij sessions + zoxide dirs. Existing session or
# directory → attach/switch/create a zellij session named after it.
#
# --dmenu: pick via `vicinae dmenu` instead of fzf, for use outside
# zellij (vicinae script command). Focuses the niri window attached to
# the session, or spawns a footclient attaching/creating it.

mode=fzf
[ "${1:-}" = "--dmenu" ] && mode=dmenu

ICON_SESSION=$'\ue795' # nf-dev-terminal — marks zellij session lines
ICON_DIR=$'\uf07b'     # nf-fa-folder — marks zoxide dir lines
# list/preview run in child bash processes spawned by fzf
export ICON_SESSION ICON_DIR

# toggle: hotkey while the picker is already open → close the old pane
# (matched by its "zs" title, set by the keybind in
# modules/home/shell/zellij.nix, excluding ourselves) and hide the
# layer instead of stacking a second picker.
if [ "$mode" = fzf ] && [ -n "${ZELLIJ:-}" ]; then
  old=$(zellij action list-panes -j 2>/dev/null \
    | jq -r --argjson me "${ZELLIJ_PANE_ID:-null}" \
        '[.[] | select((.is_plugin | not) and .title == "zs" and .id != $me)][0].id // empty') || old=""
  if [ -n "$old" ]; then
    zellij action close-pane --pane-id "$old"
    zellij action hide-floating-panes
    exit 0
  fi
fi

# lines are: icon<TAB>name<TAB>extra (created/exited info for sessions)
# ponytail: session names with spaces break the field split; default
# zellij names never contain any.
list() {
  {
    zellij ls -n 2>/dev/null \
      | sed "s/^\([^ ]*\) /  $ICON_SESSION\t\1\t/; /(current)/ { s/^  /> /; s/.*/\x1b[32m&\x1b[0m/; }" || true
    zoxide query -l | sed "s|^$HOME|~|; s|^|  $ICON_DIR\t|"
  } | awk -F'\t' '!seen[$2]++'
}
if [ "$mode" = dmenu ]; then
  # vicinae dmenu renders neither ANSI colors nor nerd-font glyphs
  disp=$(list | awk -F'\t' -v s="$ICON_SESSION" \
    '{ printf "%s %s\n", (index($1, s) ? "🖥️" : "📁"), $2 }')
  sel=$(vicinae dmenu --navigation-title 'zellij sessions' \
    --placeholder 'attach to session or dir' <<<"$disp") || exit 0
  sel=${sel#* } # strip emoji; names/dirs contain no spaces (see above)
  [ -n "$sel" ] || exit 0

  # dir lines are ~- or /-prefixed, session names are bare
  name=$sel dir=""
  case $sel in
    '~'* | /*)
      dir="${sel/#\~/$HOME}"
      name=$(basename "$dir")
      ;;
  esac
  # The session holding a client is the terminal window running zellij;
  # reuse it via switch-session instead of attaching a second client in a
  # new window. Window titles can't identify it (zellij sets "<session> |
  # <pane>" only after the active pane emits an OSC title) and neither can
  # pids (foot's server reports its own pid for every window).
  # EXITED sessions are skipped: addressing one resurrects it.
  attached=""
  while read -r s; do
    if zellij --session "$s" action list-clients 2>/dev/null | sed 1d | grep -q .; then
      attached=$s
      break
    fi
  done < <(zellij ls -n 2>/dev/null | grep -v EXITED | cut -d' ' -f1)

  if [ -n "$attached" ]; then
    # ponytail: cycles if several footclient windows exist; only one holds a
    # zellij client, match on that window's app_id if it ever matters.
    nirius focus -a footclient || true
    [ "$name" = "$attached" ] && exit 0
    if zellij ls -ns 2>/dev/null | grep -qxF "$name"; then
      zellij --session "$attached" action switch-session "$name"
    else
      zellij --session "$attached" action switch-session "$name" \
        --cwd "$dir" --layout project
    fi
  elif zellij ls -ns 2>/dev/null | grep -qxF "$name"; then
    # no client anywhere — open a window (attach resurrects exited sessions)
    setsid -f footclient zellij attach "$name" >/dev/null 2>&1 || true
  elif [ -n "$dir" ]; then
    setsid -f footclient -D "$dir" \
      zellij --session "$name" --new-session-with-layout project \
      >/dev/null 2>&1 || true
  fi
  exit 0
fi

preview() {
  if [[ "$1" == *"$ICON_SESSION" ]]; then
    local layout
    if ! layout=$(zellij --session "$2" action dump-layout 2>/dev/null); then
      echo "no layout — session exited?"
      return
    fi
    # drop new_tab_template (not real panes; closes at 4-space indent),
    # then list per tab: command pane basenames + bare self-closing
    # panes (= plain shells). Container/plugin panes have no command.
    sed '/^    new_tab_template {/,/^    }/d' <<<"$layout" \
      | awk '
          /^ *tab / { match($0, /name="[^"]*"/); print substr($0, RSTART+6, RLENGTH-7) }
          / command=/ { match($0, /command="[^"]*"/); c = substr($0, RSTART+9, RLENGTH-10); sub(/.*\//, "", c); print "  " c }
          /^ *pane[^{]*$/ && !/command|plugin/ { print "  shell" }
        '
  else
    ls -A --color=always "${2/#\~/$HOME}"
  fi
}
export -f list preview
# delete-session --force kills AND removes — plain kill-session leaves
# dead session in ls. Harmlessly fails on zoxide dir lines.
sel=$(list | SHELL=$BASH fzf --reverse --ansi --delimiter='\t' --tabstop=4 \
  --accept-nth=2 \
  --preview 'preview {1} {2}' \
  --bind 'ctrl-d:execute-silent(zellij delete-session --force {2})+reload(list)') || sel=""
# closing the floating pane doesn't hide the layer — the next floating
# pane would pop up. Hide on every path, including fzf cancel.
[ -n "${ZELLIJ:-}" ] && zellij action hide-floating-panes
[ -z "$sel" ] && exit 0

dir="${sel/#\~/$HOME}"
if [ -d "$dir" ]; then
  name=$(basename "$dir")
  if [ -n "${ZELLIJ:-}" ]; then
    zellij action switch-session "$name" --cwd "$dir" --layout project
    zellij --session "$name" action hide-floating-panes
  elif zellij ls -ns 2>/dev/null | grep -qx "$name"; then
    zellij attach "$name"
  else
    cd "$dir" && zellij --session "$name" --new-session-with-layout project
  fi
else
  if [ -n "${ZELLIJ:-}" ]; then
    zellij action switch-session "$sel"
    zellij --session "$sel" action hide-floating-panes
  else
    zellij attach "$sel"
  fi
fi
