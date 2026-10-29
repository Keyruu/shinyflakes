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

run resume "$root" >"$tmp/out"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
[ "$(jq '[.[] | select(.terminal_command | contains(" pi --session "))] | length' "$tmp/panes.json")" -eq 1 ]
! grep -q 'DO NOT REPLAY\|example/model' "$tmp/calls"
run resume "$root" >"$tmp/out"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
[ "$(grep -c '^focus-pane-id ' "$tmp/calls")" -eq 2 ]

# Native tab navigation may already restore Pi focus; a redundant focus command fails.
MOCK_ALREADY_FOCUSED=1 run resume "$root" >"$tmp/out"
MOCK_ALREADY_FOCUSED=1 run open "$root" >"$tmp/out"
[ "$(grep -c '^focus-pane-id ' "$tmp/calls")" -eq 2 ]
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]

# Switching conversation leaves original pane command unchanged; refuse wrong focus.
marker="$XDG_CACHE_HOME/pi-herd/$MOCK_PI_PID.json"
jq '.sessionId="different" | .sessionFile="/tmp/other.jsonl"' "$marker" >"$tmp/marker.next"
mv "$tmp/marker.next" "$marker"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'switched session was focused' >&2; exit 1; fi
grep -q 'active session unknown or differs' "$tmp/err"
[ "$(grep -c '^focus-pane-id ' "$tmp/calls")" -eq 2 ]
rm "$marker"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'missing live identity was focused' >&2; exit 1; fi
grep -q 'active session unknown or differs' "$tmp/err"
[ "$(grep -c '^override-layout ' "$tmp/calls" || true)" -eq 0 ]
# Stale PID must not count as a live identity.
jq -n --arg root "$root" --arg review "$review" --arg transcript "$transcript" \
  '{pid:999999,taskRoot:$root,taskReviewState:$review,zellijSession:"mock",zellijPaneId:"3",sessionId:"coordinator",sessionFile:$transcript}' >"$XDG_CACHE_HOME/pi-herd/999999.json"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'stale live identity was focused' >&2; exit 1; fi
rm "$XDG_CACHE_HOME/pi-herd/999999.json"
jq -n --arg root "$root" --arg review "$review" --arg transcript "$transcript" --argjson pid "$MOCK_PI_PID" \
  '{pid:$pid,taskRoot:$root,taskReviewState:$review,zellijSession:"mock",zellijPaneId:"3",sessionId:"coordinator",sessionFile:$transcript}' >"$marker"
run resume "$root" >"$tmp/out"
[ "$(grep -c '^focus-pane-id ' "$tmp/calls")" -eq 3 ]

# Recovery must restore geometry as well as preserve processes; concurrent resumes serialize.
jq '[.[] | select(.terminal_command | contains(" pi --session ") | not)]' "$tmp/panes.json" >"$tmp/keep"
mv "$tmp/keep" "$tmp/panes.json"
run open "$root" >"$tmp/out"
[ "$(jq length "$tmp/panes.json")" -eq 2 ]
jq 'map(.tab_name="! Renamed task")' "$tmp/panes.json" >"$tmp/survivors.json"
for change in '. + [.[0] | .id=80 | .terminal_command="unrelated"]' '.[0].is_floating=true' '.[1].is_suppressed=true' '.[0].exited=true'; do
  jq "$change" "$tmp/survivors.json" >"$tmp/panes.json"
  if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'unsupported pane set was rearranged' >&2; exit 1; fi
  grep -q 'standard Pi recovery needs' "$tmp/err"
  [ "$(jq -r '.piLaunch' "$metadata")" = false ]
done
cp "$tmp/survivors.json" "$tmp/panes.json"
SHELL=/different/caller-shell run resume "$root" >"$tmp/one" & p1=$!
run resume "$root" >"$tmp/two" & p2=$!
wait "$p1"; wait "$p2"
[ "$(grep -c '^override-layout ' "$tmp/calls")" -eq 1 ]
[ "$(jq length "$tmp/panes.json")" -eq 3 ]
jq -e --slurpfile before "$tmp/survivors.json" '
  . as $panes | all($before[0][]; . as $old | any($panes[]; . == $old))
' "$tmp/panes.json" >/dev/null
jq -e '
  (map(select(.terminal_command | endswith(" nvim")))[0]) as $editor |
  (map(select(.terminal_command | endswith(" -l")))[0]) as $shell |
  (map(select(.terminal_command | contains(" pi --session ")))[0]) as $pi |
  all(.[]; .tab_name == "! Renamed task") and
  $editor.pane_columns == 60 and $shell.pane_columns == 60 and
  $shell.pane_y == 71 and $pi.pane_x == 60 and $pi.pane_rows == 100
' "$tmp/panes.json" >/dev/null

# Last permitted visibility poll succeeds; a genuine timeout stays uncertain.
jq '[.[] | select(.terminal_command | contains(" pi --session ") | not)]' "$tmp/panes.json" >"$tmp/keep"
mv "$tmp/keep" "$tmp/panes.json"
export MOCK_VISIBLE_ON=20
run resume "$root" >"$tmp/out"
[ "$(jq -r '.piLaunch' "$metadata")" = false ]
jq '[.[] | select(.terminal_command | contains(" pi --session ") | not)]' "$tmp/panes.json" >"$tmp/keep"
mv "$tmp/keep" "$tmp/panes.json"
export MOCK_VISIBLE_ON=21
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'invisible pane reported success' >&2; exit 1; fi
grep -q 'Pi launch not visible' "$tmp/err"
[ "$(jq -r '.piLaunch' "$metadata")" = true ]
launched=$(grep -c '^override-layout ' "$tmp/calls")
export MOCK_VISIBLE_ON=999
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'uncertain launch retried' >&2; exit 1; fi
grep -q 'previous Pi launch uncertain' "$tmp/err"
[ "$(grep -c '^override-layout ' "$tmp/calls")" -eq "$launched" ]
unset MOCK_VISIBLE_ON
jq '.piLaunch=false' "$metadata" >"$tmp/metadata.next"; mv "$tmp/metadata.next" "$metadata"

# Missing transcript refuses replacement and leaves review/feedback untouched.
jq '[.[] | select(.terminal_command | contains(" pi --session ") | not)]' "$tmp/panes.json" >"$tmp/keep"
mv "$tmp/keep" "$tmp/panes.json"
rm "$transcript"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'missing transcript was accepted' >&2; exit 1; fi
grep -q 'coordinator transcript unavailable' "$tmp/err"
jq 'del(.coordinatorSession)' "$review" >"$tmp/review.next"
mv "$tmp/review.next" "$review"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'missing locator was accepted' >&2; exit 1; fi
grep -q 'no exact coordinator transcript recorded' "$tmp/err"
[ "$(grep -c '^override-layout ' "$tmp/calls")" -eq "$launched" ]
jq -e '.draft == "keep notes" and .pending.summary == "pending" and .coordinator == "coordinator"' "$review" >/dev/null

# Binding and resume accept native Pi cwd inside same checkout, reject another Git root.
mkdir -p "$root/subdir" "$tmp/other"
git -C "$tmp/other" init -q
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$root/subdir" >"$transcript"
task_review_update bind "$root" "$review" coordinator "$transcript" >/dev/null
run resume "$root" >"$tmp/out"
[ "$(grep -c '^override-layout ' "$tmp/calls")" -eq "$((launched + 1))" ]
jq '[.[] | select(.terminal_command | contains(" pi --session ") | not)]' "$tmp/panes.json" >"$tmp/keep"
mv "$tmp/keep" "$tmp/panes.json"
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$tmp/other" >"$transcript"
if task_review_update bind "$root" "$review" coordinator "$transcript" >"$tmp/out" 2>"$tmp/err"; then echo 'other checkout bound' >&2; exit 1; fi
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'other checkout resumed' >&2; exit 1; fi
grep -q 'session transcript checkout mismatch' "$tmp/err"
[ "$(grep -c '^override-layout ' "$tmp/calls")" -eq "$((launched + 1))" ]

# A visible restored Pi is not success if native placement still leaves a full-width shell.
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$root" >"$transcript"
if MOCK_BAD_LAYOUT=1 run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'wrong recovery geometry accepted' >&2; exit 1; fi
grep -q 'standard task layout was not restored' "$tmp/err"
[ "$(jq -r '.piLaunch' "$metadata")" = true ]
jq '.piLaunch=false' "$metadata" >"$tmp/metadata.next"; mv "$tmp/metadata.next" "$metadata"

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
run resume first >"$tmp/out"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
[ "$(grep -c 'Initial task only' "$tmp/calls")" -eq 1 ]
printf '[]\n' >"$tmp/panes.json"
if run resume first >"$tmp/out" 2>"$tmp/err"; then echo 'unrecorded initial session resumed' >&2; exit 1; fi
grep -q 'no exact coordinator transcript recorded' "$tmp/err"
if run open "$first" >"$tmp/out" 2>"$tmp/err"; then echo 'open restored a closed conversation' >&2; exit 1; fi
grep -q 'workspace closed; use resume' "$tmp/err"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
printf 'pi-task resume fixture: OK\n'

# Presentation tests stay inside the stub; a PTY verifies the plain-terminal branch.
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$root" >"$transcript"
reset_presentation() {
  rm -f "$marker"
  jq '.session="mock"' "$metadata" >"$tmp/metadata.next"; mv "$tmp/metadata.next" "$metadata"
  printf '[]\n' >"$tmp/panes.json"
  printf 'mock\n' >"$state/session"
  printf '{"mock":0,"caller":1}\n' >"$tmp/sessions.json"
  : >"$tmp/calls"
}
reset_presentation
export ZELLIJ_SESSION_NAME=caller
printf '{"caller":1}\n' >"$tmp/sessions.json"
run resume "$root" >"$tmp/out"
grep -q "switch-session .*'mock'.*'--layout', 'project'" "$tmp/calls"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
! grep -q '^terminal ' "$tmp/calls"
[ "$(<"$state/session")" = mock ]

reset_presentation
printf '{"mock":0,"caller":1}\n' >"$tmp/sessions.json"
run resume "$root" >"$tmp/out"
grep -q "switch-session \['mock'\]" "$tmp/calls"
! grep '^switch-session ' "$tmp/calls" | grep -q -- '--layout'

reset_presentation
export ZELLIJ_PANE_ID=999
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'stale caller accepted' >&2; exit 1; fi
grep -q 'current Zellij pane no longer exists' "$tmp/err"
! grep -q '^switch-session\|^new-tab' "$tmp/calls"
[ "$(jq -r '.piLaunch' "$metadata")" = false ]
export ZELLIJ_PANE_ID=900
printf '{"mock":0,"caller":2}\n' >"$tmp/sessions.json"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'ambiguous caller accepted' >&2; exit 1; fi
grep -q 'exactly one client' "$tmp/err"

reset_presentation
printf '{"mock":1,"caller":1}\n' >"$tmp/sessions.json"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'second target client accepted' >&2; exit 1; fi
grep -q 'already attached or client state unknown' "$tmp/err"
[ ! -s "$tmp/calls" ]
reset_presentation
export MOCK_UNKNOWN_CLIENT=mock
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'unknown target clients accepted' >&2; exit 1; fi
grep -q 'already attached or client state unknown' "$tmp/err"
[ ! -s "$tmp/calls" ]
unset MOCK_UNKNOWN_CLIENT
export MOCK_EXTRA_CLIENT=1
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'concurrent target client accepted' >&2; exit 1; fi
grep -q 'exactly one client' "$tmp/err"
! grep -q '^new-tab ' "$tmp/calls"
[ "$(jq -r '.piLaunch' "$metadata")" = false ]
unset MOCK_EXTRA_CLIENT

# Identical basenames get distinct stable session names, even from a matching cwd.
reset_presentation
rm "$state/session"
jq 'del(.session)' "$metadata" >"$tmp/metadata.next"; mv "$tmp/metadata.next" "$metadata"
(cd "$root" && run resume "$root") >"$tmp/out"
session_one=$(<"$state/session")
[[ "$session_one" == repo-* ]]
mkdir -p "$tmp/second/repo"
git -C "$tmp/second/repo" init -q
git -C "$tmp/second/repo" -c user.name=test -c user.email=test@example.org commit --allow-empty -qm base
printf '[]\n' >"$tmp/panes.json"
(cd "$tmp/second/repo" && bash "$launcher" --repo "$tmp/second/repo" new distinct --request 'Second repo') >"$tmp/out"
session_two=$(<"$tmp/second/repo/.git/pi-task/session")
[[ "$session_two" == repo-* && "$session_one" != "$session_two" ]]

# Automation must opt into a window; rejection precedes worktree creation.
reset_presentation
unset ZELLIJ ZELLIJ_SESSION_NAME ZELLIJ_PANE_ID
if run new unattended --request never </dev/null >"$tmp/out" 2>"$tmp/err"; then echo 'implicit automation accepted' >&2; exit 1; fi
grep -q 'no interactive terminal' "$tmp/err"
[ ! -e "$root.worktrees/unattended" ]
[ ! -s "$tmp/calls" ]
run state "$root" </dev/null >"$tmp/out"
if run state "$root" --window >"$tmp/out" 2>"$tmp/err"; then echo 'window accepted for state' >&2; exit 1; fi
if run --window </dev/null >"$tmp/out" 2>"$tmp/err"; then echo 'noninteractive picker accepted' >&2; exit 1; fi
grep -q 'picker requires an interactive terminal' "$tmp/err"
printf '{"mock":1}\n' >"$tmp/sessions.json"
if (cd "$tmp" && bash "$launcher" resume "$root" --window </dev/null) >"$tmp/out" 2>"$tmp/err"; then echo 'attached target accepted' >&2; exit 1; fi
grep -q 'already attached or client state unknown' "$tmp/err"
[ ! -s "$tmp/calls" ]

# The failing Kitty stub must remain unused by plain-terminal paths.
export MOCK_EXPECT_TTY=1 MOCK_LOCK="$state/launch.lock"
reset_presentation
script -q -e -c "bash '$launcher' --repo '$root' resume '$root'" /dev/null >"$tmp/out"
grep -q "terminal \['attach', 'mock'\]" "$tmp/calls"
grep -q '^terminal-exit' "$tmp/calls"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
reset_presentation
printf '{"mock":1}\n' >"$tmp/sessions.json"
if script -q -e -c "bash '$launcher' --repo '$root' resume '$root'" /dev/null >"$tmp/out"; then echo 'second terminal client accepted' >&2; exit 1; fi
grep -q 'already attached or client state unknown' "$tmp/out"
[ ! -s "$tmp/calls" ]
reset_presentation
printf '{}\n' >"$tmp/sessions.json"
script -q -e -c "bash '$launcher' --repo '$root' resume '$root'" /dev/null >"$tmp/out"
grep -q "terminal \['--session', 'mock', '--new-session-with-layout', 'project'\]" "$tmp/calls"
reset_presentation
export MOCK_TERMINAL_FAIL=1
if script -q -e -c "bash '$launcher' --repo '$root' resume '$root'" /dev/null >"$tmp/out"; then echo 'failed terminal accepted' >&2; exit 1; fi
grep -q 'Zellij exited before attaching.*7' "$tmp/out"
! grep -q '^new-tab ' "$tmp/calls"
[ "$(jq -r '.piLaunch' "$metadata")" = false ]
unset MOCK_TERMINAL_FAIL MOCK_EXPECT_TTY

# Explicit --window creates/attaches a sole client, never an ambiguous second one.
tee "$tmp/bin/kitty" >/dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'window\n' >>"$MOCK_ZELLIJ/calls"
[ "$1" = --directory ]; cd "$2"; shift 2
exec "$@"
SH
for sessions in '{"mock":0}' '{}'; do
  reset_presentation
  printf '%s\n' "$sessions" >"$tmp/sessions.json"
  run resume "$root" --window >"$tmp/out"
  [ "$(grep -c '^window$' "$tmp/calls")" -eq 1 ]
  [ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
  for attempt in {1..50}; do
    grep -q '^terminal-exit' "$tmp/calls" && break
    sleep .05
  done
  grep -q '^terminal-exit' "$tmp/calls"
done

reset_presentation
printf '{"mock":1}\n' >"$tmp/sessions.json"
if run resume "$root" --window >"$tmp/out" 2>"$tmp/err"; then echo 'second window client accepted' >&2; exit 1; fi
grep -q 'already attached or client state unknown' "$tmp/err"
[ ! -s "$tmp/calls" ]

# A successful switch command without an arriving client must not launch Pi.
reset_presentation
export ZELLIJ=0 ZELLIJ_SESSION_NAME=caller ZELLIJ_PANE_ID=900 MOCK_NO_CLIENT=1
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'missing client accepted' >&2; exit 1; fi
grep -q 'no new client attached' "$tmp/err"
! grep -q '^new-tab ' "$tmp/calls"
[ "$(jq -r '.piLaunch' "$metadata")" = false ]
unset MOCK_NO_CLIENT

reset_presentation
export ZELLIJ_SESSION_NAME=mock MOCK_CLIENT_AFTER_TAB=1
printf '{"mock":1}\n' >"$tmp/sessions.json"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'ambiguous final focus accepted' >&2; exit 1; fi
grep -q 'exactly one client before focusing' "$tmp/err"
! grep -q '^go-to-tab-by-id\|^focus-pane-id' "$tmp/calls"
[ "$(jq length "$tmp/panes.json")" -eq 3 ]
[ "$(jq -r '.piLaunch' "$metadata")" = false ]
unset MOCK_CLIENT_AFTER_TAB

# Picker exit leaves task panes intact; native close-on-exit lifecycle is source-checked separately.
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
jq -e '.draft == "keep notes" and .pending.summary == "pending" and .coordinator == "coordinator"' "$review" >/dev/null
printf 'pi-task presentation fixture: OK\n'
