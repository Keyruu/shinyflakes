#!/usr/bin/env python3
import json, os, re, shlex, subprocess, sys, time
from pathlib import Path
root = Path(os.environ['MOCK_ZELLIJ'])
args = sys.argv[1:]
sessions_file = root / 'sessions.json'
sessions = json.loads(sessions_file.read_text()) if sessions_file.exists() else {'mock': 1, 'caller': 1}
def log(text):
    with (root / 'calls').open('a') as out: out.write(text + '\n')
def attach(name):
    if os.environ.get('MOCK_NO_CLIENT'): return
    if sessions.get(name) == -1:
        log('native-resurrection ' + name)
        (root / 'panes.json').write_text((root / 'resurrect-panes.json').read_text())
    sessions[name] = max(sessions.get(name, 0), 0) + (2 if os.environ.get('MOCK_EXTRA_CLIENT') else 1)
    sessions_file.write_text(json.dumps(sessions))
def identity(pane, name):
    words = shlex.split(pane['terminal_command'])
    if 'pi' not in words: return
    path = words[words.index('--session')+1] if '--session' in words else None
    session = json.loads(Path(path).read_text().splitlines()[0])['id'] if path else words[words.index('--session-id')+1]
    record = dict(pid=int(os.environ['MOCK_PI_PID']), taskRoot=words[1].split('=',1)[1],
        taskReviewState=words[2].split('=',1)[1], zellijSession=name,
        zellijPaneId=str(pane['id']), sessionId=session, sessionFile=path)
    (root / 'cache/pi-herd').mkdir(parents=True, exist_ok=True)
    (root / 'cache/pi-herd' / (os.environ['MOCK_PI_PID'] + '.json')).write_text(json.dumps(record))
def create_layout(name, layout, initial=False):
    assert sessions.get(name, 0) > 0, 'headless task creation'
    panes = [] if initial else json.loads((root / 'panes.json').read_text())
    tab = 0 if initial else max([p['tab_id'] for p in panes], default=0) + 1
    title = json.loads(re.search(r'tab name=("(?:[^"\\]|\\.)*")', layout).group(1))
    editor_args = re.search(r'pane command="env" \{ args (.*?); \}', layout)
    shell_args = re.search(r'pane stacked=true stack_direction="horizontal" size="30%" \{\s*pane command="env" \{ args (.*?); \}', layout)
    pi_args = re.search(r'pane stacked=true stack_direction="vertical" size="40%" \{\s*pane command="env" \{ args (.*?); \}', layout)
    assert editor_args and shell_args, layout
    assert 'pane split_direction="vertical" {\n      pane split_direction="horizontal" {' in layout
    commands = ['env ' + ' '.join(shlex.split(editor_args.group(1))),
        'env ' + ' '.join(shlex.split(shell_args.group(1)))]
    if pi_args: commands.append('env ' + ' '.join(shlex.split(pi_args.group(1))))
    geometry = [(0, 1, 70, 60), (0, 71, 30, 60), (60, 1, 100, 40)]
    for cmd, (x, y, rows, columns) in zip(commands, geometry):
        pane = next((p for p in panes if p['tab_id'] == tab and p['terminal_command'] == cmd), None)
        if pane is None:
            pane = dict(id=max([p['id'] for p in panes], default=0)+1,
                is_plugin=False, exited=False, tab_id=tab, tab_name=title, terminal_command=cmd)
            panes.append(pane)
        pane.update(pane_x=x, pane_y=y, pane_rows=rows, pane_columns=columns,
            is_floating=False, is_suppressed=False)
    identity(pane, name)
    (root / 'panes.json').write_text(json.dumps(panes))
    if os.environ.get('MOCK_CLIENT_AFTER_TAB'):
        sessions[name] = 2
        sessions_file.write_text(json.dumps(sessions))
    (root / 'poll.count').write_text('0')
    return tab
def initial_layout(name, path):
    layout = Path(path).read_text()
    assert Path(path).stat().st_mode & 0o777 == 0o600
    metadata = json.loads(Path(path).with_suffix('.json').read_text())
    assert metadata.get('piLaunch') == ('"pi"' in layout)
    log('initial-layout ' + repr(layout))
    create_layout(name, layout, initial=True)
if args[:2] == ['list-sessions', '--no-formatting']:
    print('\n'.join(name if '--short' in args else
        name + ' [Created 1s ago] ' + ('(EXITED - attach to resurrect)' if count == -1 else '')
        for name, count in sessions.items())); sys.exit()
if args[0] == 'attach' or (args[0] == '--session' and args[2] != 'action'):
    name = args[1]
    log('terminal ' + repr(args))
    for key in ['ZELLIJ', 'ZELLIJ_SESSION_NAME', 'ZELLIJ_PANE_ID', 'PI_TASK_ROOT', 'PI_TASK_REVIEW_STATE']:
        assert key not in os.environ, key
    if os.environ.get('MOCK_EXPECT_TTY'): assert sys.stdin.isatty() and sys.stdout.isatty()
    if os.environ.get('MOCK_TERMINAL_FAIL'): sys.exit(7)
    attach(name)
    if '--new-session-with-layout' in args:
        initial_layout(name, args[args.index('--new-session-with-layout') + 1])
    deadline = time.monotonic() + 15
    while True:
        calls = (root / 'calls').read_text()
        navigated = 'focus-pane-id ' in calls or 'native-resurrection ' in calls
        unlocked = not os.environ.get('MOCK_LOCK') or subprocess.run(['flock', '-n', os.environ['MOCK_LOCK'], 'true']).returncode == 0
        if navigated and unlocked: break
        assert time.monotonic() < deadline, 'launcher never finished navigation or released lock'
        time.sleep(.05)
    log('terminal-exit'); sys.exit()
name = os.environ.get('ZELLIJ_SESSION_NAME', 'mock')
if args[0] == '--session':
    name = args[1]
    args = args[2:]
assert args[0] == 'action', args
act = args[1]
if sessions.get(name) == -1:
    raise AssertionError('launcher must not query panes/clients of an exited session')
panes = json.loads((root / 'panes.json').read_text()) if name != 'caller' else []
def save(): (root / 'panes.json').write_text(json.dumps(panes))
if act == 'list-clients':
    if name == os.environ.get('MOCK_UNKNOWN_CLIENT'): sys.exit(1)
    active = int((root / 'active-tab').read_text()) if (root / 'active-tab').exists() else -1
    focused = next((p['id'] for p in panes if p['tab_id'] == active and not p['exited']), 0)
    if os.environ.get('MOCK_ALREADY_FOCUSED') and panes: focused = panes[-1]['id']
    print('CLIENT_ID ZELLIJ_PANE_ID' + ''.join(f'\n{i} terminal_{focused}' for i in range(1, sessions.get(name, 0) + 1))); sys.exit()
if act == 'list-panes':
    marker = root / 'cache/pi-herd' / (os.environ['MOCK_PI_PID'] + '.json')
    if marker.exists():
        record = json.loads(marker.read_text())
        if record.get('zellijSession') == name and not any(str(p['id']) == record.get('zellijPaneId') and not p['exited'] for p in panes):
            marker.unlink()
    after = int(os.environ.get('MOCK_VISIBLE_ON', '0'))
    if after:
        counter = root / 'poll.count'
        count = int(counter.read_text()) + 1 if counter.exists() else 1
        counter.write_text(str(count))
        if count < after:
            panes = [p for p in panes if ' pi --session' not in p['terminal_command']]
    origin = [dict(id=900, tab_id=90, tab_name='origin', is_plugin=False, exited=False, terminal_command='pi-task')] if name == os.environ.get('ZELLIJ_SESSION_NAME') else []
    print(json.dumps(panes + origin)); sys.exit()
log(act + ' ' + repr(args[2:]))
if act == 'focus-pane-id' and os.environ.get('MOCK_ALREADY_FOCUSED'):
    print('Pane is already focused', file=sys.stderr); sys.exit(2)
if act == 'switch-session':
    attach(args[2])
    if '--layout' in args:
        initial_layout(args[2], args[args.index('--layout') + 1])
elif act == 'go-to-tab-by-id':
    (root / 'active-tab').write_text(args[2])
elif act == 'new-pane':
    assert '--no-focus' in args and '--stacked' in args and '--tab-id' not in args
    anchor = next(p for p in panes if p['id'] == int(os.environ['ZELLIJ_PANE_ID']) and not p['is_plugin'])
    assert not anchor['exited'] and not anchor.get('is_suppressed')
    assert any(Path(word).name in ('pi', 'pi-resurrect.ts') for word in shlex.split(anchor['terminal_command']))
    pane = dict(id=max([p['id'] for p in panes], default=0)+1, is_plugin=False, exited=False,
        tab_id=anchor['tab_id'], tab_name=anchor['tab_name'], terminal_command=' '.join(args[args.index('--')+1:]),
        **{key: anchor[key] for key in ['pane_x', 'pane_y', 'pane_rows', 'pane_columns']})
    anchor['is_suppressed'] = True
    if os.environ.get('MOCK_BAD_STACK'): pane['pane_x'] += 1
    panes.append(pane)
    identity(pane, name); save(); print('terminal_' + str(pane['id']))
elif act == 'override-layout':
    raise AssertionError('automatic layout repair is retired')
elif act == 'new-tab':
    assert '--no-focus' in args
    print(create_layout(name, args[args.index('--layout-string') + 1]))
