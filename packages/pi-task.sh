set -euo pipefail

# shellcheck source=packages/pi-task-state.sh
source "${PI_TASK_STATE_LIBRARY:-$(dirname "${BASH_SOURCE[0]}")/pi-task-state.sh}"

if [ "${1:-}" = review-internal ]; then
  shift
  task_review_command "$@"
  exit
fi

usage() {
  printf '%s\n' \
    'pi-task [--repo DIR] new NAME [--base REF] [--request TEXT]' \
    'pi-task [--repo DIR] open [WORKTREE] [--adopt include|trust]' \
    'pi-task [--repo DIR] state [WORKTREE]  # saved review state, no launch' \
    'new/open: --review-mode autonomous|guided (saved task review policy)' \
    'pi-task                         # repository/worktree picker'
}
fail() { printf 'pi-task: %s\n' "$*" >&2; exit 1; }
quote() { jq -cn --arg text "$1" '$text'; }

repo="" base=HEAD request="" review_mode="" adopt=""
args=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo|--base|--request|--review-mode|--adopt)
      [ "$#" -ge 2 ] || fail "$1 needs a value"
      case "$1" in
        --repo) repo=$2 ;;
        --base) base=$2 ;;
        --request) request=$2 ;;
        --review-mode) review_mode=$2 ;;
        --adopt) adopt=$2 ;;
      esac
      shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; args+=("$@"); break ;;
    -*) fail "unknown option: $1" ;;
    *) args+=("$1"); shift ;;
  esac
done
[ "${#args[@]}" -le 2 ] || fail 'too many arguments'
action=${args[0]:-pick}
case "$action" in pick|new|open|state) ;; *) fail "unknown action: $action" ;; esac
case "$review_mode" in ''|autonomous|guided) ;; *) fail 'review mode must be autonomous or guided' ;; esac
case "$adopt" in ''|include|trust) ;; *) fail 'adoption must be include or trust' ;; esac
if [ "$action" = state ]; then
  [ -z "$request$review_mode$adopt" ] || fail 'state only reads existing review state'
elif [ "$action" = new ]; then
  [ -z "$adopt" ] || fail '--adopt is only for existing worktrees'
fi

if [ -z "$repo" ]; then
  if [ "$action" = pick ] || ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    repo=$({ pwd; zoxide query -l; } | while IFS= read -r directory; do
      git -C "$directory" rev-parse --show-toplevel 2>/dev/null || true
    done | awk '!seen[$0]++' | fzf --prompt='Repository > ') || exit 0
  else
    repo=.
  fi
fi
repo=$(git -C "$repo" rev-parse --show-toplevel) || fail 'select a non-bare Git repository'
repo=$(realpath "$repo")
common=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir)
worktrees=()
while IFS= read -r -d '' entry; do
  case "$entry" in worktree\ *) worktrees+=("${entry#worktree }") ;; esac
done < <(git -C "$repo" worktree list --porcelain -z)
main=${worktrees[0]}
if [ "$action" = pick ] || { [ "$action" = open ] && [ "${#args[@]}" -eq 1 ]; }; then
  selected=$(printf '%s\n' '[new task]' "${worktrees[@]}" | fzf --prompt='Task > ') || exit 0
  if [ "$selected" = '[new task]' ]; then
    action=new
    read -r -p 'Task name: ' name </dev/tty || exit 0
    read -r -p 'Request (empty = idle): ' request </dev/tty || exit 0
  else
    action=open
    name=$selected
  fi
else
  name=${args[1]:-}
  if [ "$action" = state ] && [ -z "$name" ]; then name=$repo; fi
fi
[ -n "$name" ] || fail 'task name or worktree path required'

state="$common/pi-task"
mkdir -p "$state"
# Serialize launch, not agent writes: double hotkeys must not create duplicate tabs.
exec {launch_lock}>"$state/launch.lock"
flock "$launch_lock"

if [ "$action" = new ]; then
  [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || fail 'use letters, digits, dots, underscores or hyphens for task names'
  git check-ref-format --branch "task/$name" >/dev/null || fail 'invalid task branch name'
  commit=$(git -C "$repo" rev-parse --verify --end-of-options "${base}^{commit}") || fail 'base must resolve to a commit'
  worktree="${main}.worktrees/$name"
  git -C "$repo" worktree add -b "task/$name" "$worktree" "$commit"
  if [ -f "$worktree/.gitmodules" ]; then
    git -C "$worktree" submodule update --init --recursive || fail "submodule initialization failed; worktree preserved at $worktree"
  fi
else
  [ -z "$request" ] || fail '--request is only valid for new tasks; reopening never replays prompts'
  worktree=$(git -C "$name" rev-parse --show-toplevel) || fail 'worktree does not exist'
  worktree=$(realpath "$worktree")
  found=false
  for path in "${worktrees[@]}"; do
    if [ "$(realpath "$path")" = "$worktree" ]; then found=true; break; fi
  done
  "$found" || fail 'worktree belongs to a different repository'
fi
worktree=$(realpath "$worktree")
hash=$(printf '%s' "$worktree" | sha256sum)
hash=${hash:0:12}
metadata="$state/$hash.json"
review_file="$state/reviews/$hash.json"
if [ "$action" = state ]; then
  [ -f "$review_file" ] || fail 'worktree has no review state; open it to adopt it first'
  task_review_validate "$worktree" "$review_file"
  jq . "$review_file"
  exit 0
fi
if [ ! -f "$review_file" ] && [ -z "$adopt" ] && [ -t 0 ] &&
  [ -n "$(GIT_OPTIONAL_LOCKS=0 git -C "$worktree" status --porcelain=v1 --untracked-files=all --ignore-submodules=none)" ]; then
  printf 'Existing edits: include in first review (i), or trust current state (t)? ' >&2
  read -r choice </dev/tty || exit 0
  case "$choice" in
    i|include) adopt=include ;;
    t|trust) adopt=trust ;;
    *) fail 'no adoption choice; worktree preserved without launching' ;;
  esac
fi
task_review_init "$worktree" "$review_file" "$review_mode" "$adopt"

session=""
if [ -f "$state/session" ]; then IFS= read -r session <"$state/session" || true; fi
live_sessions=$(zellij list-sessions --no-formatting --short 2>/dev/null || true)
if [ -z "$session" ] || ! grep -qxF -- "$session" <<<"$live_sessions"; then
  current_common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
  if [ -n "${ZELLIJ_SESSION_NAME:-}" ] && [ "$current_common" = "$common" ]; then
    session=$ZELLIJ_SESSION_NAME
  else
    repo_hash=$(printf '%s' "$common" | sha256sum)
    session="$(basename "$main" | tr -c 'a-zA-Z0-9_-' '-')-${repo_hash:0:8}"
  fi
fi
printf '%s\n' "$session" >"$state/session"

if [ "$worktree" = "$main" ]; then label=main; else label="task:$(basename "$worktree")"; fi
label="$label:$hash"
root_arg="$(quote "PI_TASK_ROOT=$worktree") $(quote "PI_TASK_REVIEW_STATE=$review_file")"
pi_args="\"pi\""
if [ -n "$request" ]; then pi_args="$pi_args \"--\" $(quote "$request")"; fi
shell_arg=$(quote "${SHELL:-bash}")
layout="layout {
  default_tab_template {
    pane size=1 borderless=true { plugin location=\"zellij:tab-bar\"; }
    children
    pane size=1 borderless=true { plugin location=\"zellij:status-bar\"; }
  }
  tab name=$(quote "$label") cwd=$(quote "$worktree") {
    pane split_direction=\"vertical\" {
      pane split_direction=\"horizontal\" {
        pane command=\"env\" { args $root_arg \"nvim\"; }
        pane size=\"30%\" command=\"env\" { args $root_arg $shell_arg \"-l\"; }
      }
      pane size=\"40%\" command=\"env\" { args $root_arg $pi_args; }
    }
  }
  swap_floating_layout {
    floating_panes { pane { width \"80%\"; height \"80%\"; x \"10%\"; y \"10%\"; }; }
  }
}"

panes="[]"
if grep -qxF -- "$session" <<<"$live_sessions"; then
  panes=$(zellij --session "$session" action list-panes --json --all)
fi
saved_tab=null
if [ -f "$metadata" ]; then saved_tab=$(jq -r '.tabId // "null"' "$metadata"); fi
tab=$(jq -r --arg root "$worktree" --arg label "$label" --argjson saved "$saved_tab" '
  [.[] | select(.is_plugin | not) | select(.pane_cwd == $root or .tab_name == $label or .tab_name == ("! " + $label))]
  | sort_by(if .tab_id == $saved then 0 else 1 end) | .[0].tab_id // empty
' <<<"$panes")

if [ -z "$tab" ]; then
  if grep -qxF -- "$session" <<<"$live_sessions"; then
    tab=$(zellij --session "$session" action new-tab --layout-string "$layout" --cwd "$worktree" --name "$label")
  else
    # --layout-string with a session name dispatches NewTab, not session creation.
    layout_file=$(mktemp "$state/.layout.XXXXXX.kdl")
    printf '%s\n' "$layout" >"$layout_file"
    trap 'rm -f "$layout_file"' EXIT
    env -u ZELLIJ -u ZELLIJ_SESSION_NAME zellij --new-session-with-layout "$layout_file" attach --create-background "$session"
    rm "$layout_file"
    trap - EXIT
    tab=$(zellij --session "$session" action list-panes --json --tab | jq -r '[.[] | select(.is_plugin | not)][0].tab_id')
  fi
fi
[[ "$tab" =~ ^[0-9]+$ ]] || fail 'Zellij did not return a task tab ID'
if [ ! -f "$metadata" ]; then
  jq -n --arg root "$worktree" --arg request "$request" '{root: $root, request: $request}' >"$metadata"
fi
updated=$(mktemp "$state/.workspace.XXXXXX")
jq --arg session "$session" --argjson tab "$tab" '. + {session: $session, tabId: $tab}' "$metadata" >"$updated"
mv "$updated" "$metadata"
flock -u "$launch_lock"

zellij --session "$session" action go-to-tab-by-id "$tab"
if [ -n "${ZELLIJ:-}" ]; then
  if [ -n "${ZELLIJ_PANE_ID:-}" ]; then
    origin_tab=$(zellij action list-panes --json --tab | jq -r --argjson own "$ZELLIJ_PANE_ID" '[.[] | select((.is_plugin | not) and .id == $own)][0].tab_id // empty')
    if [ -n "$origin_tab" ]; then
      status=0
      zellij action hide-floating-panes --tab-id "$origin_tab" || status=$?
      # The fork reports an already-hidden layer as exit 2.
      [ "$status" -eq 0 ] || [ "$status" -eq 2 ] || fail 'could not hide task picker'
    fi
  fi
  if [ "$session" != "${ZELLIJ_SESSION_NAME:-}" ]; then
    zellij action switch-session "$session"
  fi
else
  exec zellij attach "$session"
fi
