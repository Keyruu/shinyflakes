# fzf picker over all running pi instances (status published by the
# tool-guardian herd.ts module). Meant to run in a zellij floating pane;
# selecting an entry jumps to that instance's pane, across sessions.
#
# --dmenu: pick via `vicinae dmenu` instead of fzf, for use outside
# zellij (vicinae script command). Jumps by focusing the pane inside the
# target session and then the Umbriel window showing that session.

dir="${XDG_CACHE_HOME:-$HOME/.cache}/pi-herd"
mode=fzf
for arg in "$@"; do
  case "$arg" in
    --dmenu) mode=dmenu ;;
    -h|--help) printf '%s\n' 'pi-herd [--dmenu] — navigate to running Pi; /review opens diff'; exit 0 ;;
    *) printf 'pi-herd: unknown option: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

F_SESSION=2
F_PANE=3
F_PID=4

# Closing the floating pane doesn't hide the layer — the next floating
# pane (e.g. lazygit) would pop up. Hide on every exit path; our own
# hidden pane keeps running and close_on_exit reaps it. No-op outside
# zellij so --dmenu / direct runs don't die on it (errexit).
hide_panes() {
  if [ -n "${ZELLIJ:-}" ]; then
    zellij action hide-floating-panes
  fi
}

# switch-session to a dead name silently creates a new session — callers
# must verify the recorded name is still a live session first.
session_alive() {
  zellij list-sessions -n 2>/dev/null | awk '!/EXITED/ {print $1}' \
    | grep -qxF "$1"
}

# toggle: hotkey while the picker is already open → close the old
# pane (matched by its "pi herd" title, excluding ourselves) and
# hide the layer instead of stacking a second picker.
if [ "$mode" = fzf ] && [ -n "${ZELLIJ:-}" ]; then
  old=$(zellij action list-panes -j 2>/dev/null \
    | jq -r --argjson me "${ZELLIJ_PANE_ID:-null}" \
        '[.[] | select((.is_plugin | not) and .title == "pi herd" and .id != $me)][0].id // empty') || old=""
  if [ -n "$old" ]; then
    zellij action close-pane --pane-id "$old"
    zellij action hide-floating-panes
    exit 0
  fi
fi

rows=""
for f in "$dir"/*.json; do
  [ -e "$f" ] || continue
  row=$(jq -r '[.pid, .status, .cwd, .zellijSession // "-", .zellijPaneId // "-", .zellijTab // "-", (.updatedAt | tostring)] | @tsv' "$f")
  pid=${row%%$'\t'*}
  # GC entries from crashed/killed pi processes
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$f"
    continue
  fi
  row=$(jq -r '[.pid, .status, .taskRoot // .cwd, .zellijSession // "-", .zellijPaneId // "-", .zellijTab // "-", (.updatedAt | tostring)] | @tsv' "$f")
  rows+="$row"$'\n'
done

if [ -z "$rows" ]; then
  echo "no running pi instances"
  if [ "$mode" = "fzf" ]; then
    read -rsn1
    hide_panes
  fi
  exit 0
fi

# ZELLIJ_SESSION_NAME is captured at pane spawn and goes stale when a
# session is renamed — comparing stale names misroutes same-session
# jumps into switch-session, which silently creates a phantom session.
# Same session = same ancestor zellij server process; compare pids.
server_of() { # pid -> ancestor zellij server pid
  local p=$1
  while [ -n "$p" ] && [ "$p" -gt 1 ]; do
    if [ "$(cat "/proc/$p/comm" 2>/dev/null)" = "zellij" ]; then
      printf '%s\n' "$p"
      return 0
    fi
    p=$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null)
  done
  return 1
}

now=$(date +%s)
lines=$(while IFS=$'\t' read -r pid status cwd session pane tab ts; do
  [ -n "$pid" ] || continue
  age=$((now - ts))
  if [ "$age" -lt 60 ]; then age="${age}s"
  elif [ "$age" -lt 3600 ]; then age="$((age / 60))m"
  else age="$((age / 3600))h"; fi
  case "$status" in
    waiting)  sort=1; icon=$'\e[31m●\e[0m'; emoji=🔴 ;;
    question) sort=1; icon=$'\e[36m●\e[0m'; emoji=❓ ;;
    working) sort=2; icon=$'\e[33m●\e[0m'; emoji=🟡 ;;
    *)       sort=3; icon=$'\e[2m○\e[0m'; emoji=⚪ ;;
  esac
  if [ "$mode" = dmenu ]; then
    loc=$tab
    [ "$pane" != "-" ] && loc="$tab · p$pane"
    printf '%s\t%s\t%s\t%s\t%s %-7s\t%s\t%s\t%s\t%s\n' \
      "$sort" "$session" "$pane" "$pid" \
      "$emoji" "$status" "${cwd/#"$HOME"/\~}" "$session" "$loc" "$age"
  else
    repo=$cwd
    # Git's first worktree is the main checkout, even for adopted worktrees elsewhere.
    if IFS= read -r -d '' main < <(git -C "$cwd" worktree list --porcelain -z 2>/dev/null); then
      repo=${main#worktree }
    fi
    project=$(basename "$repo")
    title=$tab
    [ "$title" != "-" ] || title=$(basename "$cwd")
    loc=$session
    [ "$pane" != "-" ] && loc="$session · p$pane"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t  %s %-7s  %s\t%s\t%s\t%s\n' \
      "$sort" "$session" "$pane" "$pid" "$repo" "$project" \
      "$icon" "$status" "$title" "${cwd/#"$HOME"/\~}" "$loc" "$age"
  fi
done <<<"$rows" | if [ "$mode" = dmenu ]; then
  sort -t$'\t' -k1,1 -k7,7
else
  sort -t$'\t' -k5,5 -k1,1n -k7,7
fi)

if [ "$mode" = "dmenu" ]; then
  disp=$(cut -f5- <<<"$lines" | tr '\t' ' ')
  sel_disp=$(vicinae dmenu --navigation-title 'pi herd' \
    --placeholder 'jump to instance' <<<"$disp") || exit 0
  # map the display line back to its meta row by line number
  # ponytail: identical display lines resolve to the first match — can't
  # collide in practice since the line includes session + pane id
  n=$(grep -nxF -- "$sel_disp" <<<"$disp" | head -1 | cut -d: -f1)
  [ -n "$n" ] || exit 0
  sel=$(sed -n "${n}p" <<<"$lines")
  session=$(cut -f"$F_SESSION" <<<"$sel")
  pane=$(cut -f"$F_PANE" <<<"$sel")
  [ "$session" = "-" ] && exit 0
  if ! session_alive "$session"; then
    echo "session '$session' no longer exists (renamed?)"
    exit 0
  fi
  # the zellij CLI resolves the target socket from ZELLIJ_SESSION_NAME,
  # so this works from outside any session
  if [ "$pane" != "-" ]; then
    ZELLIJ_SESSION_NAME=$session zellij action focus-pane-id "$pane"
  fi
  # focus the window attached to the session (title: "<session> | ...")
  win=$(umbriel windows --json \
    | jq -r --arg p "$session | " \
      '[.[] | select(.title | startswith($p))][0].id // empty') || win=""
  if [ -n "$win" ]; then
    umbriel msg window-focus "$win"
  else
    # session not attached in any window — open one
    setsid -f kitty zellij attach "$session" >/dev/null 2>&1 || true
  fi
  exit 0
fi

lines=$(awk -F '\t' -v home="$HOME" '
  $5 != previous {
    path = $5
    if (index(path, home "/") == 1) path = "~" substr(path, length(home) + 1)
    printf "group\t-\t-\t-\t%s\t%s\t\033[1;36m── %s · %s ──\033[0m\n", $5, $6, $6, path
    previous = $5
  }
  { print }
' <<<"$lines")

# ponytail: divider rows filter normally; use reload-based grouping if search must retain them.
sel=$(fzf --ansi --layout=reverse --no-sort --no-multi --delimiter=$'\t' --with-nth=7.. \
  --bind='load:transform:test {1} = group && echo down' \
  --bind='enter,double-click:transform:test {1} != group && echo accept' \
  --header='pi herd — enter: jump to task; /review opens task diff' <<<"$lines") || sel=""

if [ -z "$sel" ]; then
  hide_panes
  exit 0
fi

session=$(cut -f"$F_SESSION" <<<"$sel")
pane=$(cut -f"$F_PANE" <<<"$sel")
pid=$(cut -f"$F_PID" <<<"$sel")
if [ "$session" = "-" ]; then
  hide_panes
  exit 0
fi

my_srv=$(server_of "$$") || my_srv=""
entry_srv=$(server_of "$pid") || entry_srv=""

# same server process = same session, regardless of any rename
if [ -n "$entry_srv" ] && [ "$entry_srv" = "$my_srv" ]; then
  hide_panes
  [ "$pane" != "-" ] && zellij action focus-pane-id "$pane"
  exit 0
fi

# ponytail: a renamed foreign session isn't resolvable by name; bail.
if ! session_alive "$session"; then
  echo "session '$session' no longer exists (renamed?)"
  read -rsn1
  hide_panes
  exit 0
fi

hide_panes
if [ "$pane" != "-" ]; then
  zellij action switch-session "$session" --pane-id "terminal_$pane"
else
  zellij action switch-session "$session"
fi
