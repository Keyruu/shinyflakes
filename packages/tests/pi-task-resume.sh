#!/usr/bin/env bash
set -euo pipefail

launcher=$(realpath "$(dirname "$0")/../pi-task.sh")
lib=$(realpath "$(dirname "$0")/../pi-task-state.sh")
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/repo"
git -C "$tmp/repo" init -q
git -C "$tmp/repo" -c user.name=test -c user.email=test@example.org commit --allow-empty -qm base
root=$(realpath "$tmp/repo")
common=$(git -C "$root" rev-parse --path-format=absolute --git-common-dir)
key=$(printf '%s' "$root" | sha256sum); key=${key:0:12}
state="$common/pi-task"
review="$state/reviews/$key.json"
metadata="$state/$key.json"
source "$lib"
task_review_init "$root" "$review" '' '' HEAD
transcript="$tmp/session.jsonl"
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$root" >"$transcript"
review_json=$(jq --arg file "$transcript" '.coordinator="coordinator" | .coordinatorSession=$file | .draft="keep notes" | .pending={id:"review",summary:"pending",checks:""}' "$review")
printf '%s\n' "$review_json" >"$review"
jq -n --arg root "$root" '{root:$root,request:"DO NOT REPLAY",model:"example/model",title:"fixture",session:"mock",piLaunch:false}' >"$metadata"
printf 'mock\n' >"$state/session"
printf '[]\n' >"$tmp/panes.json"
: >"$tmp/calls"

# Stub Zellij: no live user session touched. Persist pane membership across invocations.
cp "$(dirname "$0")/fixtures/pi-task-zellij.py" "$tmp/bin/zellij"
chmod +x "$tmp/bin/zellij"
printf '#!/usr/bin/env bash\nexit 99\n' >"$tmp/bin/kitty"
chmod +x "$tmp/bin/kitty"
# script must not run fish startup and replace the stub-only command precedence.
export MOCK_ZELLIJ="$tmp" MOCK_PI_PID=$$ XDG_CACHE_HOME="$tmp/cache" PATH="$tmp/bin:$PATH" SHELL=/bin/sh
unset ENV BASH_ENV PI_TASK_ROOT PI_TASK_REVIEW_STATE PI_TASK_SHARED
export ZELLIJ=0 ZELLIJ_SESSION_NAME=mock ZELLIJ_PANE_ID=900
run() { bash "$launcher" --repo "$root" "$@"; }

# Start with a verified live workspace; resume must only navigate it.
mkdir -p "$XDG_CACHE_HOME/pi-herd"
marker="$XDG_CACHE_HOME/pi-herd/$MOCK_PI_PID.json"
jq -n --arg root "$root" --arg review "$review" --arg transcript "$transcript" '
  ("env PI_TASK_ROOT=" + $root + " PI_TASK_REVIEW_STATE=" + $review + " ") as $prefix |
  [range(1;4) | {id:.,tab_id:1,tab_name:"! Renamed task",is_plugin:false,exited:false,
    terminal_command:($prefix + (if . == 1 then "nvim" elif . == 2 then "/bin/sh -l" else "pi --session " + $transcript end)),
    pane_x:0,pane_y:0,pane_rows:30,pane_columns:80}]' >"$tmp/panes.json"
jq -n --arg root "$root" --arg review "$review" --arg transcript "$transcript" --argjson pid "$MOCK_PI_PID" \
  '{pid:$pid,taskRoot:$root,taskReviewState:$review,zellijSession:"mock",zellijPaneId:"3",sessionId:"coordinator",sessionFile:$transcript}' >"$marker"
cp "$tmp/panes.json" "$tmp/live-panes.json"
cp "$marker" "$tmp/live-marker.json"
cp "$review" "$tmp/saved-review.json"
run resume "$root" >"$tmp/out"
run resume "$root" >"$tmp/out"
[ "$(grep -c '^focus-pane-id ' "$tmp/calls")" -eq 2 ]
! grep -q '^new-tab\|^new-pane\|^override-layout\|DO NOT REPLAY\|example/model' "$tmp/calls"

# Native tab navigation may already restore Pi focus; do not issue a redundant focus.
MOCK_ALREADY_FOCUSED=1 run resume "$root" >"$tmp/out"
MOCK_ALREADY_FOCUSED=1 run open "$root" >"$tmp/out"
[ "$(grep -c '^focus-pane-id ' "$tmp/calls")" -eq 2 ]

# The launch command alone cannot establish the currently active Pi conversation.
jq '.sessionId="different" | .sessionFile="/tmp/other.jsonl"' "$marker" >"$tmp/marker.next"
mv "$tmp/marker.next" "$marker"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'switched session was focused' >&2; exit 1; fi
grep -q 'active session unknown or differs' "$tmp/err"
rm "$marker"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'missing live identity was focused' >&2; exit 1; fi
grep -q 'active session unknown or differs' "$tmp/err"
jq '.pid=999999' "$tmp/live-marker.json" >"$XDG_CACHE_HOME/pi-herd/999999.json"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'stale live identity was focused' >&2; exit 1; fi
rm "$XDG_CACHE_HOME/pi-herd/999999.json"
cp "$tmp/live-marker.json" "$marker"
run resume "$root" >"$tmp/out"
[ "$(grep -c '^focus-pane-id ' "$tmp/calls")" -eq 3 ]

# Missing Pi is explicit recovery, regardless of survivor geometry or concurrency.
jq '[.[] | select(.id != 3)]' "$tmp/live-panes.json" >"$tmp/survivors.json"
rm "$marker"
for change in '.' '. + [.[0] | .id=80 | .terminal_command="unrelated"]' '.[0].is_floating=true' '.[1].is_suppressed=true' '.[0].exited=true'; do
  jq "$change" "$tmp/survivors.json" >"$tmp/panes.json"
  cp "$tmp/panes.json" "$tmp/before.json"
  if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'missing Pi was repaired' >&2; exit 1; fi
  grep -q 'automatic pane repair is retired' "$tmp/err"
  grep -q 'pi --resume' "$tmp/err"
  cmp "$tmp/before.json" "$tmp/panes.json"
done
cp "$tmp/survivors.json" "$tmp/panes.json"
run open "$root" >"$tmp/out"
cmp "$tmp/survivors.json" "$tmp/panes.json"
(run resume "$root" >"$tmp/one" 2>&1 && exit 1 || grep -q 'automatic pane repair is retired' "$tmp/one") & p1=$!
(run resume "$root" >"$tmp/two" 2>&1 && exit 1 || grep -q 'automatic pane repair is retired' "$tmp/two") & p2=$!
wait "$p1"; wait "$p2"
! grep -q '^new-tab\|^new-pane\|^override-layout' "$tmp/calls"
cmp "$tmp/saved-review.json" "$review"

# Deleted/mismatched transcripts never cause fallback to a new conversation.
rm "$transcript"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'session transcript unavailable' "$tmp/err"
jq 'del(.coordinatorSession)' "$review" >"$tmp/review.next"; mv "$tmp/review.next" "$review"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'no exact coordinator transcript recorded' "$tmp/err"
mkdir -p "$root/subdir" "$tmp/other"
git -C "$tmp/other" init -q
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$root/subdir" >"$transcript"
task_review_update bind "$root" "$review" coordinator "$transcript" >/dev/null
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'automatic pane repair is retired' "$tmp/err"
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$tmp/other" >"$transcript"
if task_review_update bind "$root" "$review" coordinator "$transcript" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'session transcript checkout mismatch' "$tmp/err"
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$root" >"$transcript"
diff -u <(jq -S . "$tmp/saved-review.json") <(jq -S . "$review")
cp "$review" "$tmp/saved-review.json"

# First launch delivers request/model once; live resume uses saved initial identity.
printf '[]\n' >"$tmp/panes.json"
: >"$tmp/calls"
run new first --request 'Initial task only' --model example/model >"$tmp/out"
first="$root.worktrees/first"
first_key=$(jq -r --arg root "$first" 'select(.root == $root) | .id' "$state"/*.json)
first_metadata="$state/$first_key.json"
first_review="$state/reviews/$first_key.json"
[ "$(grep -c 'Initial task only' "$tmp/calls")" -eq 1 ]
jq -e '.request == "Initial task only" and .model == "example/model" and .piLaunch == false' "$first_metadata" >/dev/null
[ "$(jq -r '.base' "$first_review")" = "$(git -C "$root" rev-parse HEAD)" ]
first_session=$(jq -r '.session' "$first_metadata")
[[ "$first_session" == repo-first-* ]]
grep -F "switch-session ['$first_session', '--cwd', '$first', '--layout', 'project']" "$tmp/calls"
[ "$(<"$state/session")" = mock ]
export ZELLIJ_SESSION_NAME="$first_session"
run resume first >"$tmp/out"
run open "$first" >"$tmp/out"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
[ "$(grep -c 'Initial task only' "$tmp/calls")" -eq 1 ]
cp "$tmp/panes.json" "$tmp/first-panes.json"
cp "$marker" "$tmp/first-marker.json"

# A second task in the same repository gets its own session, not another task tab.
printf '[]\n' >"$tmp/panes.json"
run new second >"$tmp/out"
second_metadata=$(jq -r --arg root "$root.worktrees/second" 'select(.root == $root) | .id' "$state"/*.json)
second_session=$(jq -r '.session' "$state/$second_metadata.json")
[[ "$second_session" == repo-second-* && "$second_session" != "$first_session" ]]
grep -F "switch-session ['$second_session', '--cwd', '$root.worktrees/second', '--layout', 'project']" "$tmp/calls"
[ "$(jq -r '.session' "$first_metadata")" = "$first_session" ]
[ "$(<"$state/session")" = mock ]

# Return to the detached first session without duplicating Pi or replaying its request.
cp "$tmp/first-panes.json" "$tmp/panes.json"
cp "$tmp/first-marker.json" "$marker"
jq --arg first "$first_session" '.[$first]=0' "$tmp/sessions.json" >"$tmp/sessions.next"
mv "$tmp/sessions.next" "$tmp/sessions.json"
export ZELLIJ_SESSION_NAME="$second_session"
run open "$first" >"$tmp/out"
grep -F "switch-session ['$first_session']" "$tmp/calls"
export ZELLIJ_SESSION_NAME="$first_session"
run resume first >"$tmp/out"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 2 ]
[ "$(grep -c 'Initial task only' "$tmp/calls")" -eq 1 ]
[ "$(<"$state/session")" = mock ]
printf '[]\n' >"$tmp/panes.json"
if run resume first >"$tmp/out" 2>"$tmp/err"; then echo 'unrecorded initial session resumed' >&2; exit 1; fi
grep -q 'no exact coordinator transcript recorded' "$tmp/err"
if run open "$first" >"$tmp/out" 2>"$tmp/err"; then echo 'open restored a closed conversation' >&2; exit 1; fi
grep -q 'workspace closed; use resume' "$tmp/err"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 2 ]
printf 'pi-task resume fixture: OK\n'

# Presentation tests stay inside the stub; exited sessions restore through native attach/switch.
reset_presentation() {
  jq '.session="mock"' "$metadata" >"$tmp/metadata.next"; mv "$tmp/metadata.next" "$metadata"
  cp "$tmp/live-panes.json" "$tmp/panes.json"
  cp "$tmp/live-marker.json" "$marker"
  printf '{"mock":0,"caller":1}\n' >"$tmp/sessions.json"
  : >"$tmp/calls"
}
closed_workspace() {
  reset_presentation
  rm "$marker"
  printf '[]\n' >"$tmp/panes.json"
  # Native pane IDs/layout differ from launch metadata, and commands start suspended.
  jq 'map(.id += 100 | .tab_id=12 | .exited=true | .terminal_command="node --experimental-strip-types /source/pi-resurrect.ts SAVED_SPEC")' \
    "$tmp/live-panes.json" >"$tmp/resurrect-panes.json"
  printf '{"mock":-1,"caller":1}\n' >"$tmp/sessions.json"
}
assert_native_restore() {
  grep -q '^native-resurrection mock$' "$tmp/calls"
  ! grep -q '^new-tab\|^new-pane\|^override-layout\|^go-to-tab-by-id\|^focus-pane-id\|DO NOT REPLAY\|example/model\|force-run-commands' "$tmp/calls"
  cmp "$tmp/resurrect-panes.json" "$tmp/panes.json"
  cmp "$tmp/saved-review.json" "$review"
}
export ZELLIJ_SESSION_NAME=caller
closed_workspace
run resume "$root" >"$tmp/out"
grep -F "switch-session ['mock']" "$tmp/calls"
grep -q 'Confirm suspended commands' "$tmp/out"
assert_native_restore

closed_workspace
if run open "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'open resurrected a closed session' >&2; exit 1; fi
grep -q 'workspace closed; use resume' "$tmp/err"
[ ! -s "$tmp/calls" ]
# No native snapshot means no replacement project layout or new task tab.
printf '{"caller":1}\n' >"$tmp/sessions.json"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'missing workspace recreated' >&2; exit 1; fi
grep -q 'automatic pane repair is retired' "$tmp/err"
[ ! -s "$tmp/calls" ]

reset_presentation
run resume "$root" >"$tmp/out"
grep -F "switch-session ['mock']" "$tmp/calls"
! grep -q '^new-tab\|^native-resurrection' "$tmp/calls"

reset_presentation
export ZELLIJ_PANE_ID=999
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'current Zellij pane no longer exists' "$tmp/err"
! grep -q '^switch-session\|^new-tab' "$tmp/calls"
export ZELLIJ_PANE_ID=900
printf '{"mock":0,"caller":2}\n' >"$tmp/sessions.json"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'exactly one client' "$tmp/err"

reset_presentation
printf '{"mock":1,"caller":1}\n' >"$tmp/sessions.json"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'already attached or client state unknown' "$tmp/err"
[ ! -s "$tmp/calls" ]
reset_presentation
export MOCK_UNKNOWN_CLIENT=mock
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'already attached or client state unknown' "$tmp/err"
[ ! -s "$tmp/calls" ]
unset MOCK_UNKNOWN_CLIENT
closed_workspace
export MOCK_EXTRA_CLIENT=1
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'exactly one client' "$tmp/err"
! grep -q '^new-tab\|^focus-pane-id' "$tmp/calls"
unset MOCK_EXTRA_CLIENT

# Automation must opt into a window; rejection precedes worktree creation.
reset_presentation
unset ZELLIJ ZELLIJ_SESSION_NAME ZELLIJ_PANE_ID
if run new unattended --request never </dev/null >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'no interactive terminal' "$tmp/err"
[ ! -e "$root.worktrees/unattended" ]
[ ! -s "$tmp/calls" ]
run state "$root" </dev/null >"$tmp/out"
if run state "$root" --window >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
if run --window </dev/null >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'picker requires an interactive terminal' "$tmp/err"

# Both live attachment and native resurrection work in a plain terminal; no Kitty.
export MOCK_EXPECT_TTY=1 MOCK_LOCK="$state/launch.lock"
reset_presentation
script -q -e -c "bash '$launcher' --repo '$root' resume '$root'" /dev/null >"$tmp/out"
grep -F "terminal ['attach', 'mock']" "$tmp/calls"
grep -q '^terminal-exit' "$tmp/calls"
! grep -q '^new-tab' "$tmp/calls"
closed_workspace
script -q -e -c "bash '$launcher' --repo '$root' resume '$root'" /dev/null >"$tmp/out"
grep -q '^terminal-exit' "$tmp/calls"
assert_native_restore
reset_presentation
printf '{"mock":1}\n' >"$tmp/sessions.json"
if script -q -e -c "bash '$launcher' --repo '$root' resume '$root'" /dev/null >"$tmp/out"; then exit 1; fi
grep -q 'already attached or client state unknown' "$tmp/out"
[ ! -s "$tmp/calls" ]
closed_workspace
export MOCK_TERMINAL_FAIL=1
if script -q -e -c "bash '$launcher' --repo '$root' resume '$root'" /dev/null >"$tmp/out"; then exit 1; fi
grep -q 'Zellij exited before attaching.*7' "$tmp/out"
! grep -q '^new-tab\|^native-resurrection' "$tmp/calls"
unset MOCK_TERMINAL_FAIL MOCK_EXPECT_TTY

# --window likewise delegates native resurrection without forcing pane commands.
tee "$tmp/bin/kitty" >/dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'window\n' >>"$MOCK_ZELLIJ/calls"
[ "$1" = --directory ]; cd "$2"; shift 2
exec "$@"
SH
for mode in live closed; do
  if [ "$mode" = live ]; then reset_presentation; else closed_workspace; fi
  run resume "$root" --window >"$tmp/out"
  [ "$(grep -c '^window$' "$tmp/calls")" -eq 1 ]
  ! grep -q '^new-tab' "$tmp/calls"
  for attempt in {1..50}; do
    grep -q '^terminal-exit' "$tmp/calls" && break
    sleep .05
  done
  grep -q '^terminal-exit' "$tmp/calls"
  if [ "$mode" = closed ]; then assert_native_restore; fi
done
reset_presentation
printf '{"mock":1}\n' >"$tmp/sessions.json"
if run resume "$root" --window >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'already attached or client state unknown' "$tmp/err"
[ ! -s "$tmp/calls" ]

closed_workspace
export ZELLIJ=0 ZELLIJ_SESSION_NAME=caller ZELLIJ_PANE_ID=900 MOCK_NO_CLIENT=1
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'no new client attached' "$tmp/err"
! grep -q '^new-tab\|^native-resurrection' "$tmp/calls"
unset MOCK_NO_CLIENT

# Initial-launch visibility and uncertain-delivery checks still apply to new tasks.
reset_presentation
export ZELLIJ_SESSION_NAME=mock
printf '{"mock":1}\n' >"$tmp/sessions.json"
MOCK_VISIBLE_ON=20 run new delayed >"$tmp/out"
delayed=$(jq -r 'select(.name=="delayed") | .session' "$state"/*.json)
export ZELLIJ_SESSION_NAME="$delayed"
if MOCK_VISIBLE_ON=21 run new invisible >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'Pi launch not visible' "$tmp/err"
invisible=$(jq -r 'select(.name=="invisible") | .id' "$state"/*.json)
jq -e '.piLaunch == true' "$state/$invisible.json" >/dev/null
rm -f "$marker"
printf '[]\n' >"$tmp/panes.json"
launched=$(grep -c '^new-tab ' "$tmp/calls")
if run resume "$invisible" >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'previous Pi launch uncertain' "$tmp/err"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq "$launched" ]

reset_presentation
export ZELLIJ_SESSION_NAME=mock
printf '{"mock":1}\n' >"$tmp/sessions.json"
if MOCK_CLIENT_AFTER_TAB=1 run new ambiguous >"$tmp/out" 2>"$tmp/err"; then exit 1; fi
grep -q 'exactly one client before focusing' "$tmp/err"
! grep -q '^go-to-tab-by-id\|^focus-pane-id' "$tmp/calls"

# Picker navigation never submits feedback or mutates the workspace.
reset_presentation
printf '{"mock":1}\n' >"$tmp/sessions.json"
tee "$tmp/bin/fzf" >/dev/null <<'PY'
#!/usr/bin/env python3
import sys
print(sys.stdin.readline().rstrip())
PY
chmod +x "$tmp/bin/fzf"
cp "$tmp/panes.json" "$tmp/before-picker.json"
run review >"$tmp/out"
cmp "$tmp/before-picker.json" "$tmp/panes.json"
! grep -q '^close-pane\|^kill-session\|^delete-session' "$tmp/calls"
cmp "$tmp/saved-review.json" "$review"
printf 'pi-task native recovery/presentation fixture: OK\n'
