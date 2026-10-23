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
    'pi-task [--repo DIR] new NAME [--base REF] [--request TEXT] [--model PATTERN]' \
    'pi-task [--repo DIR] open [WORKTREE] [--adopt include] [--base COMMIT] [--model PATTERN]' \
    'pi-task [--repo DIR] resume NAME|WORKTREE  # focus coordinator or restore exact session' \
    'pi-task [--repo DIR] migrate WORKTREE --base COMMIT  # preserves legacy backup'  \
    'pi-task [--repo DIR] state [WORKTREE]  # saved review state, no launch' \
    'pi-task [--repo DIR] review  # pending reviews; navigate without resuming' \
    'pi-task [--repo DIR] title TEXT  # display title only; no launch/focus' \
    'new/open: --review-mode autonomous|guided (legacy metadata only; review is manual)' \
    'new/open: --model PATTERN  # passed to pi as --model, e.g. qwen-token-plan/kimi-k2.7-code' \
    'pi-task                         # repository/worktree picker'
}
fail() { printf 'pi-task: %s\n' "$*" >&2; exit 1; }
quote() { jq -cn --arg text "$1" '$text'; }

repo="" base=HEAD explicit_base=false request="" review_mode="" adopt="" model=""
args=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo|--base|--request|--review-mode|--adopt|--model)
      [ "$#" -ge 2 ] || fail "$1 needs a value"
      case "$1" in
        --repo) repo=$2 ;;
        --base) base=$2; explicit_base=true ;;
        --request) request=$2 ;;
        --review-mode) review_mode=$2 ;;
        --adopt) adopt=$2 ;;
        --model) model=$2 ;;
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
case "$action" in pick|new|open|resume|state|migrate|review|title) ;; *) fail "unknown action: $action" ;; esac
if [ "$action" = resume ] && { [ "${#args[@]}" -ne 2 ] || [ -n "$request$review_mode$adopt$model" ] || "$explicit_base"; }; then
  fail 'resume only accepts an existing task name or worktree path'
fi
if [ "$action" = title ]; then
  if [ -n "$request$review_mode$adopt$model" ] || "$explicit_base"; then fail 'title only accepts display text'; fi
  title=$(jq -nr --arg text "${args[1]:-}" '$text | gsub("^\\s+|\\s+$"; "")')
  jq -en --arg title "$title" '$title | length > 0 and length <= 80
    and (test("[\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}]") | not)
    and (startswith("! ") | not)' >/dev/null || fail 'title must be 1–80 printable characters, without reserved ! prefix'
fi
if [ "$action" = review ]; then
  if [ "${#args[@]}" -ne 1 ] || [ -n "$request$review_mode$adopt$model" ] || "$explicit_base"; then fail 'review only selects pending tasks'; fi
fi
case "$review_mode" in ''|autonomous|guided) ;; *) fail 'review mode must be autonomous or guided' ;; esac
case "$adopt" in ''|include) ;; *) fail 'use --adopt include with a committed --base; dirty trust baselines are retired' ;; esac
if [ "$action" = migrate ]; then
  "$explicit_base" || fail 'migration requires explicit --base COMMIT'
  [ -z "$request$review_mode$adopt$model" ] || fail 'migration only accepts --base'
fi
if [ "$action" = state ]; then
  [ -z "$request$review_mode$adopt$model" ] || fail 'state only reads existing review state'
elif [ "$action" = new ]; then
  [ -z "$adopt" ] || fail '--adopt is only for existing worktrees'
fi

if [ -z "$repo" ] && [ "$action" = title ] && [ -n "${PI_TASK_ROOT:-}" ]; then repo=$PI_TASK_ROOT; fi
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
if [ "$action" = pick ] || [ "$action" = review ] || { [ "$action" = open ] && [ "${#args[@]}" -eq 1 ]; }; then
  rows=""
  for path in "${worktrees[@]}"; do
    key=$(printf '%s' "$path" | sha256sum); key=${key:0:12}
    record="$common/pi-task/$key.json"
    review="$common/pi-task/reviews/$key.json"
    pending=false summary="" display=$(basename "$path")
    if [ -f "$record" ]; then display=$(jq -r --arg fallback "$display" '.title // $fallback' "$record"); fi
    if [ -f "$review" ]; then
      task_review_validate "$path" "$review"
      pending=$(jq -r '.pending != null' "$review")
      summary=$(jq -r '.pending.summary // "" | gsub("[\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}]"; " ") | .[0:160]' "$review")
    fi
    if [ "$action" = review ] && ! "$pending"; then continue; fi
    priority=1 badge=""
    if "$pending"; then priority=0; badge='REVIEW · '; fi
    rows+=$(printf '%s\t%s\t%s%s\t%s\t%s' "$priority" "$(quote "$path")" "$badge" "$display" "$summary" "$path")$'\n'
  done
  if [ "$action" != review ]; then rows+=$(printf '2\t%s\t[new task]' "$(quote '[new task]')")$'\n'; fi
  if [ -z "$rows" ]; then printf '%s\n' 'No pending task reviews.'; exit 0; fi
  selected=$(printf '%s' "$rows" | sort -t$'\t' -k1,1n -k3,3 | fzf --delimiter=$'\t' --with-nth=3.. --prompt='Task > ') || exit 0
  selected=$(cut -f2 <<<"$selected" | jq -r .)
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

# A spawned server or terminal must not keep the repository's launch lock alive.
without_launch_lock() (
  exec {launch_lock}>&-
  "$@"
)

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
  [ -z "$request" ] || fail '--request is only valid for new tasks; recovery never replays it'
  if [ "$action" = title ]; then name=$repo; fi
  if [ "$action" = resume ]; then
    case "$name" in */*|.|..) ;; *) name="${main}.worktrees/$name" ;; esac
  fi
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
if [ "$action" = migrate ]; then
  task_review_migrate "$worktree" "$review_file" "$base"
  exit 0
fi
if [ "$action" = title ] || [ "$action" = resume ]; then
  [ -f "$metadata" ] && [ -f "$review_file" ] || fail 'task has no saved workspace and review state'
  task_review_validate "$worktree" "$review_file"
fi
if [ -f "$review_file" ] && "$explicit_base"; then
  fail 'task base is immutable; --base only applies to adoption or explicit legacy migration'
fi
if [ ! -f "$review_file" ] && [ -z "$adopt" ] && [ -t 0 ] &&
  [ -n "$(GIT_OPTIONAL_LOCKS=0 git -C "$worktree" status --porcelain=v1 --untracked-files=all --ignore-submodules=none)" ]; then
  printf 'Include existing edits in review against committed base (i), or cancel? ' >&2
  read -r choice </dev/tty || exit 0
  case "$choice" in
    i|include) adopt=include ;;
    *) fail 'no adoption choice; worktree preserved without launching' ;;
  esac
fi
if [ "$action" != title ] && [ "$action" != resume ]; then task_review_init "$worktree" "$review_file" "$review_mode" "$adopt" "$base"; fi

session=""
if [ -f "$state/session" ]; then IFS= read -r session <"$state/session" || true; fi
live_sessions=$(zellij list-sessions --no-formatting --short 2>/dev/null || true)
if [ -z "$session" ] || ! grep -qxF -- "$session" <<<"$live_sessions"; then
  current_common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
  if [ -n "${ZELLIJ_SESSION_NAME:-}" ] && [ "$current_common" = "$common" ] &&
    grep -qxF -- "$ZELLIJ_SESSION_NAME" <<<"$live_sessions"; then
    session=$ZELLIJ_SESSION_NAME
  else
    session=$(printf '%s' "$(basename "$main")" | tr -c 'a-zA-Z0-9_-' '-')
  fi
fi
if [ "$action" != title ]; then printf '%s\n' "$session" >"$state/session"; fi

if [ "$worktree" = "$main" ]; then label=main; else label=$(basename "$worktree"); fi
saved='{}'
had_metadata=false
if [ -f "$metadata" ]; then
  had_metadata=true
  saved=$(jq -ce --arg root "$worktree" 'select(.root == $root)' "$metadata") || fail 'workspace attachment root mismatch'
  label=$(jq -r --arg fallback "$label" '.title // $fallback' <<<"$saved")
  [ -n "$request" ] || request=$(jq -r '.request // empty' <<<"$saved")
  [ -n "$model" ] || model=$(jq -r '.model // empty' <<<"$saved")
fi
if [ "$action" != title ]; then
  # Record launch intent before pane creation: uncertain first delivery must not be replayed.
  updated=$(mktemp "$state/.workspace.XXXXXX")
  jq -n --argjson saved "$saved" --arg root "$worktree" --arg request "$request" \
    --arg model "$model" --arg title "$label" --arg session "$session" \
    '$saved + {root: $root, request: $request, model: $model, title: $title, session: $session}' >"$updated"
  mv "$updated" "$metadata"
fi
root_arg="$(quote "PI_TASK_ROOT=$worktree") $(quote "PI_TASK_REVIEW_STATE=$review_file")"
pi_command="env PI_TASK_ROOT=$worktree PI_TASK_REVIEW_STATE=$review_file pi"
recovery="cd $(printf '%q' "$worktree") && PI_TASK_ROOT=$(printf '%q' "$worktree") PI_TASK_REVIEW_STATE=$(printf '%q' "$review_file") pi --resume"
panes="[]"
if grep -qxF -- "$session" <<<"$live_sessions"; then
  panes=$(zellij --session "$session" action list-panes --json --all)
fi
saved_tab=null
if [ -f "$metadata" ]; then saved_tab=$(jq -r '.tabId // "null"' "$metadata"); fi
# Zellij retains the original launch command even after cwd/title changes.
# Validate the task binding there; tab IDs alone can belong to a new server.
launch_command="env PI_TASK_ROOT=$worktree PI_TASK_REVIEW_STATE=$review_file "
tab=$(jq -r --arg command "$launch_command" --argjson saved "$saved_tab" '
  [.[] | select(.is_plugin == false) | select((.terminal_command // "") | startswith($command))]
  | map(.tab_id) | unique | if length == 1 then .[0] else empty end
' <<<"$panes")
# A stale saved tab ID is never enough to identify a task. Multiple matching tabs are unsafe.
if jq -e --arg command "$launch_command" '[.[] | select(.is_plugin == false and ((.terminal_command // "") | startswith($command))) | .tab_id] | unique | length > 1' <<<"$panes" >/dev/null; then
  fail 'multiple live task tabs; cannot identify coordinator safely'
fi

if [ "$action" = title ]; then
  if [ -n "$tab" ]; then
    label=$title
    if jq -e --argjson tab "$tab" 'any(.[]; .tab_id == $tab and (.tab_name | startswith("! ")))' <<<"$panes" >/dev/null; then label="! $title"; fi
    zellij --session "$session" action rename-tab --tab-id "$tab" -- "$label"
  fi
  updated=$(mktemp "$state/.workspace.XXXXXX")
  jq --arg title "$title" '.title = $title' "$metadata" >"$updated"
  mv "$updated" "$metadata"
  printf '%s\n' "$title"
  exit 0
fi

# The review record owns the exact Pi locator; the original request is metadata only.
coordinator=$(jq -r '.coordinator // empty' "$review_file")
transcript=$(jq -r '.coordinatorSession // empty' "$review_file")
pi_panes='[]'
if [ -n "$tab" ]; then
  pi_panes=$(jq -c --argjson tab "$tab" --arg command "$pi_command" '
    [.[] | select(.is_plugin == false and .tab_id == $tab and .exited == false)
      | select((.terminal_command // "") as $c | ($c == $command or ($c | startswith($command + " "))))]
  ' <<<"$panes")
fi
if [ "$(jq length <<<"$pi_panes")" -gt 1 ]; then fail 'multiple live Pi panes in task tab; choose coordinator explicitly'; fi
pi_pane=$(jq -r '.[0].id // empty' <<<"$pi_panes")
if [ -n "$pi_pane" ]; then
  expected_id=${coordinator:-$(jq -r '.initialSessionId // empty' <<<"$saved")}
  matches=0
  for marker in "${XDG_CACHE_HOME:-$HOME/.cache}/pi-herd/"*.json; do
    [ -f "$marker" ] || continue
    pid=${marker##*/}; pid=${pid%.json}
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    kill -0 "$pid" 2>/dev/null || continue
    if jq -e --argjson pid "$pid" --arg root "$worktree" --arg state "$review_file" \
      --arg session "$session" --arg pane "$pi_pane" '
      .pid == $pid and .taskRoot == $root and .taskReviewState == $state
      and .zellijSession == $session and .zellijPaneId == $pane' "$marker" >/dev/null 2>&1; then
      matches=$((matches + 1))
      if [ -n "$expected_id" ] && jq -e --arg id "$expected_id" --arg file "$transcript" '
        .sessionId == $id and ($file == "" or .sessionFile == $file)' "$marker" >/dev/null 2>&1; then
        live_identity=true
      else
        live_identity=false
      fi
    fi
  done
  [ "$matches" -eq 1 ] && [ "${live_identity:-false}" = true ] ||
    fail 'live Pi active session unknown or differs from saved coordinator; inspect its pane or explicitly transfer with /review-coordinator (no replacement launched)'
fi
if [ -z "$pi_pane" ]; then
  if [ "$action" = open ] && [ -n "$tab" ]; then
    printf 'Workspace open without Pi. Use pi-task --repo %q resume %q to restore coordinator.\n' "$main" "$worktree"
  else
    if [ -n "$transcript" ]; then
      if ! task_review_session_cwd "$worktree" "$transcript" "$coordinator" >/dev/null; then
        fail "coordinator transcript unavailable or mismatched: $transcript; run: $recovery; select session or start fresh explicitly, then /review-coordinator to transfer ownership"
      fi
    fi
    if [ "$action" = open ] && "$had_metadata"; then
      fail 'workspace closed; use resume to restore conversation (open only navigates)'
    fi
    if [ "$(jq -r '.piLaunch // false' <<<"$saved")" = true ]; then
      fail "previous Pi launch uncertain; inspect workspace, then run: $recovery; request will not be resent"
    fi
    if [ -z "$transcript" ] && { [ "$action" = resume ] || [ -n "$coordinator" ]; }; then
      fail "no exact coordinator transcript recorded; initial delivery may be uncertain. Run: $recovery; select session or start fresh explicitly, then /review-coordinator to transfer ownership"
    fi
    pi_args='"pi"'
    if [ -n "$transcript" ]; then
      pi_args="$pi_args \"--session\" $(quote "$transcript")"
      expected_command="$pi_command --session $transcript"
    else
      initial_id=$(uuidgen)
      pi_args="$pi_args \"--session-id\" $(quote "$initial_id")"
      expected_command="$pi_command --session-id $initial_id"
      if [ -n "$model" ]; then pi_args="$pi_args \"--model\" $(quote "$model")"; fi
      if [ "$action" = new ] && [ -n "$request" ]; then pi_args="$pi_args \"--\" $(quote "$request")"; fi
    fi
    updated=$(mktemp "$state/.workspace.XXXXXX")
    jq --arg id "${initial_id:-}" '.piLaunch = true | if $id == "" then . else .initialSessionId = $id end' "$metadata" >"$updated"
    mv "$updated" "$metadata"
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
  fi
fi

# Headless sessions can lose new panes. Attach a real client before adding tabs.
client_attached() {
  timeout 1s zellij --session "$session" action list-clients 2>/dev/null |
    awk 'NR == 1 { header=($1 == "CLIENT_ID") } NR > 1 && header && $1 ~ /^[0-9]+$/ { found=1 } END { exit !found }'
}
if ! client_attached; then
  command -v footclient >/dev/null || fail "footclient required; reopen with: pi-task --repo $(printf '%q' "$main") open $(printf '%q' "$worktree")"
  client_args=(attach "$session")
  if ! grep -qxF -- "$session" <<<"$live_sessions"; then
    client_args=(--session "$session" --new-session-with-layout project)
  fi
  without_launch_lock setsid -f env -u ZELLIJ -u ZELLIJ_SESSION_NAME -u ZELLIJ_PANE_ID \
    -u PI_TASK_ROOT -u PI_TASK_REVIEW_STATE footclient -D "$main" zellij "${client_args[@]}" \
    >/dev/null 2>&1 || fail "could not open terminal; reopen with: pi-task --repo $(printf '%q' "$main") open $(printf '%q' "$worktree")"
  deadline=$((SECONDS + 10))
  until client_attached; do
    ((SECONDS < deadline)) || fail "no client attached to $session; reopen with: pi-task --repo $(printf '%q' "$main") open $(printf '%q' "$worktree")"
    sleep 0.1
  done
fi

if [ -z "$tab" ]; then
  [ -n "${layout:-}" ] || fail 'workspace missing; use resume to restore it'
  tab=$(without_launch_lock zellij --session "$session" action new-tab --layout-string "$layout" --cwd "$worktree" --name="$label")
else
  label=$(jq -r --argjson tab "$tab" '[.[] | select((.is_plugin | not) and .tab_id == $tab)][0].tab_name | sub("^! "; "")' <<<"$panes")
  if [ -n "${layout:-}" ]; then
    pi_command_args=(env "PI_TASK_ROOT=$worktree" "PI_TASK_REVIEW_STATE=$review_file" pi)
    if [ -n "$transcript" ]; then pi_command_args+=(--session "$transcript")
    else
      pi_command_args+=(--session-id "$initial_id")
      if [ -n "$model" ]; then pi_command_args+=(--model "$model"); fi
    fi
    pi_pane=$(without_launch_lock zellij --session "$session" action new-pane --tab-id "$tab" --no-focus --cwd "$worktree" --name="pi: $label" -- "${pi_command_args[@]}")
    [[ "$pi_pane" =~ ^terminal_[0-9]+$ ]] || fail 'Zellij did not return a Pi pane ID'
  fi
fi
if [ -n "${layout:-}" ]; then
  # Do not release launch lock until Zellij exposes the new coordinator pane.
  visible=false
  for attempt in {1..20}; do
    panes=$(zellij --session "$session" action list-panes --json --all)
    if jq -e --argjson tab "$tab" --arg command "$expected_command" '
      any(.[]; .is_plugin == false and .exited == false and .tab_id == $tab and
        ((.terminal_command // "") | startswith($command)))' <<<"$panes" >/dev/null; then
      visible=true
      break
    fi
    if [ "$attempt" -lt 20 ]; then sleep 0.1; fi
  done
  "$visible" || fail 'Pi launch not visible; delivery uncertain. Inspect workspace before retrying'
  updated=$(mktemp "$state/.workspace.XXXXXX")
  jq '.piLaunch = false' "$metadata" >"$updated"; mv "$updated" "$metadata"
  pi_pane=$(jq -r --argjson tab "$tab" --arg command "$expected_command" '
    [.[] | select(.is_plugin == false and .exited == false and .tab_id == $tab)
      | select((.terminal_command // "") | startswith($command))]
    | if length == 1 then "terminal_" + (.[0].id | tostring) else empty end
  ' <<<"$panes")
  [ -n "$pi_pane" ] || fail 'Pi coordinator pane ambiguous after launch'
fi
[[ "$tab" =~ ^[0-9]+$ ]] || fail 'Zellij did not return a task tab ID'
updated=$(mktemp "$state/.workspace.XXXXXX")
jq --arg session "$session" --argjson tab "$tab" --arg title "$label" '. + {session: $session, tabId: $tab, title: $title}' "$metadata" >"$updated"
mv "$updated" "$metadata"
flock -u "$launch_lock"
exec {launch_lock}>&-

printf 'Task: %s\nSession: %s\n' "$worktree" "$session"
zellij --session "$session" action go-to-tab-by-id "$tab"
if [ -n "$pi_pane" ]; then zellij --session "$session" action focus-pane-id "$pi_pane"; fi
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
fi
