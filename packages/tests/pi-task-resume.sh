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
task_review_save "$review" "$review_json"
jq -n --arg root "$root" '{root:$root,request:"DO NOT REPLAY",model:"example/model",title:"fixture",session:"mock",piLaunch:false}' >"$metadata"
printf 'mock\n' >"$state/session"
printf '[]\n' >"$tmp/panes.json"
: >"$tmp/calls"

# Stub Zellij: no live user session touched. Persist pane membership across invocations.
tee "$tmp/bin/zellij" >/dev/null <<'PY'
#!/usr/bin/env python3
import json, os, re, shlex, sys
from pathlib import Path
root = Path(os.environ['MOCK_ZELLIJ'])
args = sys.argv[1:]
if args[:2] == ['list-sessions', '--no-formatting']:
    print('mock'); sys.exit()
if args[:2] == ['--session', 'mock']:
    args = args[2:]
assert args[0] == 'action', args
act = args[1]
panes = json.loads((root / 'panes.json').read_text())
def save(): (root / 'panes.json').write_text(json.dumps(panes))
def identity(pane):
    words = shlex.split(pane['terminal_command'])
    if 'pi' not in words: return
    path = words[words.index('--session')+1] if '--session' in words else None
    session = json.loads(Path(path).read_text().splitlines()[0])['id'] if path else words[words.index('--session-id')+1]
    record = dict(pid=int(os.environ['MOCK_PI_PID']), taskRoot=words[1].split('=',1)[1],
        taskReviewState=words[2].split('=',1)[1], zellijSession='mock',
        zellijPaneId=str(pane['id']), sessionId=session, sessionFile=path)
    (root / 'cache/pi-herd').mkdir(parents=True, exist_ok=True)
    (root / 'cache/pi-herd' / (os.environ['MOCK_PI_PID'] + '.json')).write_text(json.dumps(record))
if act == 'list-clients':
    print('CLIENT_ID\n1'); sys.exit()
if act == 'list-panes':
    after = int(os.environ.get('MOCK_VISIBLE_ON', '0'))
    if after:
        counter = root / 'poll.count'
        count = int(counter.read_text()) + 1 if counter.exists() else 1
        counter.write_text(str(count))
        if count < after:
            print(json.dumps([p for p in panes if ' pi --session ' not in p['terminal_command']])); sys.exit()
    print(json.dumps(panes)); sys.exit()
with (root / 'calls').open('a') as out: out.write(act + ' ' + repr(args[2:]) + '\n')
if act == 'new-tab':
    layout = args[args.index('--layout-string') + 1]
    tab = max([p['tab_id'] for p in panes], default=0) + 1
    bind = re.search(r'args ("PI_TASK_ROOT=.*?") ("PI_TASK_REVIEW_STATE=.*?") "nvim"', layout)
    pi_args = re.search(r'pane size="40%" command="env" \{ args (.*?); \}', layout)
    assert bind and pi_args, layout
    prefix = 'env ' + ' '.join(shlex.split(' '.join(bind.groups())))
    for cmd in ('nvim', 'bash -l', ' '.join(shlex.split(pi_args.group(1))[2:])):
        panes.append(dict(id=max([p['id'] for p in panes], default=0)+1,
            is_plugin=False, exited=False, tab_id=tab, tab_name='fixture',
            terminal_command=prefix + ' ' + cmd))
    identity(panes[-1]); save(); print(tab)
    (root / 'poll.count').write_text('0')
elif act == 'new-pane':
    cmd = ' '.join(args[args.index('--')+1:])
    pane = dict(id=max([p['id'] for p in panes], default=0)+1,
        is_plugin=False, exited=False, tab_id=int(args[args.index('--tab-id')+1]),
        tab_name='fixture', terminal_command=cmd)
    panes.append(pane); identity(pane); save(); print('terminal_' + str(pane['id']))
    (root / 'poll.count').write_text('0')
PY
chmod +x "$tmp/bin/zellij"
export MOCK_ZELLIJ="$tmp" MOCK_PI_PID=$$ XDG_CACHE_HOME="$tmp/cache" PATH="$tmp/bin:$PATH" PI_TASK_STATE_LIBRARY="$lib"
unset ZELLIJ ZELLIJ_SESSION_NAME ZELLIJ_PANE_ID PI_TASK_ROOT PI_TASK_REVIEW_STATE
run() { bash "$launcher" --repo "$root" "$@"; }

run resume "$root" >"$tmp/out"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
[ "$(jq '[.[] | select(.terminal_command | contains(" pi --session "))] | length' "$tmp/panes.json")" -eq 1 ]
! grep -q 'DO NOT REPLAY\|example/model' "$tmp/calls"
run resume "$root" >"$tmp/out"
[ "$(grep -c '^new-tab ' "$tmp/calls")" -eq 1 ]
[ "$(grep -c '^focus-pane-id ' "$tmp/calls")" -eq 2 ]

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
[ "$(grep -c '^new-pane ' "$tmp/calls" || true)" -eq 0 ]
# Stale PID must not count as a live identity.
jq -n --arg root "$root" --arg review "$review" --arg transcript "$transcript" \
  '{pid:999999,taskRoot:$root,taskReviewState:$review,zellijSession:"mock",zellijPaneId:"3",sessionId:"coordinator",sessionFile:$transcript}' >"$XDG_CACHE_HOME/pi-herd/999999.json"
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'stale live identity was focused' >&2; exit 1; fi
rm "$XDG_CACHE_HOME/pi-herd/999999.json"
jq -n --arg root "$root" --arg review "$review" --arg transcript "$transcript" --argjson pid "$MOCK_PI_PID" \
  '{pid:$pid,taskRoot:$root,taskReviewState:$review,zellijSession:"mock",zellijPaneId:"3",sessionId:"coordinator",sessionFile:$transcript}' >"$marker"
run resume "$root" >"$tmp/out"
[ "$(grep -c '^focus-pane-id ' "$tmp/calls")" -eq 3 ]

# Surviving editor and shell: only Pi is added. Concurrent resumes must serialize.
jq '[.[] | select(.terminal_command | contains(" pi --session ") | not)]' "$tmp/panes.json" >"$tmp/keep"
mv "$tmp/keep" "$tmp/panes.json"
run open "$root" >"$tmp/out"
[ "$(jq length "$tmp/panes.json")" -eq 2 ]
run resume "$root" >"$tmp/one" & p1=$!
run resume "$root" >"$tmp/two" & p2=$!
wait "$p1"; wait "$p2"
[ "$(grep -c '^new-pane ' "$tmp/calls")" -eq 1 ]
[ "$(jq length "$tmp/panes.json")" -eq 3 ]

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
launched=$(grep -c '^new-pane ' "$tmp/calls")
export MOCK_VISIBLE_ON=999
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'uncertain launch retried' >&2; exit 1; fi
grep -q 'previous Pi launch uncertain' "$tmp/err"
[ "$(grep -c '^new-pane ' "$tmp/calls")" -eq "$launched" ]
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
[ "$(grep -c '^new-pane ' "$tmp/calls")" -eq "$launched" ]
jq -e '.draft == "keep notes" and .pending.summary == "pending" and .coordinator == "coordinator"' "$review" >/dev/null

# Binding and resume accept native Pi cwd inside same checkout, reject another Git root.
mkdir -p "$root/subdir" "$tmp/other"
git -C "$tmp/other" init -q
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$root/subdir" >"$transcript"
task_review_update bind "$root" "$review" coordinator "$transcript" >/dev/null
run resume "$root" >"$tmp/out"
[ "$(grep -c '^new-pane ' "$tmp/calls")" -eq "$((launched + 1))" ]
jq '[.[] | select(.terminal_command | contains(" pi --session ") | not)]' "$tmp/panes.json" >"$tmp/keep"
mv "$tmp/keep" "$tmp/panes.json"
printf '{"type":"session","version":3,"id":"coordinator","cwd":"%s"}\n' "$tmp/other" >"$transcript"
if task_review_update bind "$root" "$review" coordinator "$transcript" >"$tmp/out" 2>"$tmp/err"; then echo 'other checkout bound' >&2; exit 1; fi
if run resume "$root" >"$tmp/out" 2>"$tmp/err"; then echo 'other checkout resumed' >&2; exit 1; fi
grep -q 'session transcript checkout mismatch' "$tmp/err"
[ "$(grep -c '^new-pane ' "$tmp/calls")" -eq "$((launched + 1))" ]
printf 'pi-task resume fixture: OK\n'
