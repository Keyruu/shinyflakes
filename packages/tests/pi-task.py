#!/usr/bin/env python3
"""Run with python3 packages/tests/pi-task.py; --live also checks real Zellij/Neovim."""
import errno
import json
import os
from pathlib import Path
import pty
import shlex
import shutil
import subprocess
import sys
import tempfile
import threading
import time

LAUNCHER = Path(__file__).resolve().parents[1] / "pi-task.sh"

with tempfile.TemporaryDirectory(prefix="pi-task-check-") as tmp:
    root = Path(tmp)
    repo = root / "repo ' spaced"
    repo.mkdir()
    subprocess.run(["git", "init", "-q", str(repo)], check=True)

    def git(*args):
        return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()

    (repo / "tracked").write_text("committed\n")
    git("add", "tracked")
    git("-c", "user.name=Check", "-c", "user.email=check@example.invalid", "commit", "-qm", "initial")
    (repo / "tracked").write_text("human dirty edit\n")
    (repo / "untracked").write_text("human untracked file\n")
    original_status = git("status", "--porcelain")

    commands = root / "bin"
    commands.mkdir()
    state = root / "zellij.json"
    state.write_text(json.dumps({"session": "", "panes": [], "layouts": []}))
    mock = commands / "zellij"
    mock.write_text('''#!/usr/bin/env python3
import json, os, re, sys
from pathlib import Path
p = Path(os.environ["MOCK_ZELLIJ"])
s = json.loads(p.read_text())
a = sys.argv[1:]
session = s["session"]
if a[:1] == ["--session"]:
    session = a[1]
    a = a[2:]
if a[:1] == ["list-sessions"]:
    print(s["session"])
elif a[:2] == ["action", "list-panes"]:
    print(json.dumps(s["panes"]))
elif "--layout-string" in a or "--new-session-with-layout" in a:
    if "--layout-string" in a:
        layout = a[a.index("--layout-string") + 1]
    else:
        layout = Path(a[a.index("--new-session-with-layout") + 1]).read_text()
        session = a[-1]
    match = re.search(r'tab name=("(?:[^"\\\\]|\\\\.)*") cwd=("(?:[^"\\\\]|\\\\.)*")', layout)
    assert match, layout
    name, cwd = map(json.loads, match.groups())
    tab = max([p["tab_id"] for p in s["panes"]], default=-1) + 1
    s["session"] = session
    s["panes"].append({"id": tab * 10, "is_plugin": False, "tab_id": tab, "tab_name": name, "pane_cwd": cwd})
    s["layouts"].append(layout)
    if a[:2] == ["action", "new-tab"]: print(tab)
elif a[:2] == ["action", "go-to-tab-by-id"]:
    s["focused"] = int(a[2])
elif a[:1] == ["attach"]:
    pass
else:
    raise SystemExit("unexpected Zellij call: " + repr(a))
p.write_text(json.dumps(s))
''')
    mock.chmod(0o755)
    env = {k: v for k, v in os.environ.items() if not k.startswith("ZELLIJ")}
    env.update(PATH=f"{commands}:{env['PATH']}", MOCK_ZELLIJ=str(state), SHELL="/bin/bash")

    def launch(*args, ok=True):
        result = subprocess.run(["bash", str(LAUNCHER), "--repo", str(repo), *args],
                                cwd=repo, env=env, text=True, capture_output=True)
        assert (result.returncode == 0) == ok, result.stdout + result.stderr
        return json.loads(state.read_text())

    request = '-- Explain "why"\nDo not execute $(touch BAD)'
    s = launch("new", "alpha", "--request", request)
    alpha = Path(str(repo) + ".worktrees") / "alpha"
    assert (alpha / "tracked").read_text() == "committed\n"
    assert not (alpha / "untracked").exists()
    assert not (repo / "BAD").exists()
    assert json.dumps(request) in s["layouts"][0]
    assert f"PI_TASK_ROOT={alpha}" in s["layouts"][0]
    assert git("status", "--porcelain") == original_status

    s = launch("new", "beta")
    assert len(s["layouts"]) == 2
    session = s["session"]
    assert s["panes"][0]["pane_cwd"] != s["panes"][1]["pane_cwd"]
    s["panes"][0]["tab_name"] = "! " + s["panes"][0]["tab_name"]
    state.write_text(json.dumps(s))
    s = launch("open", str(alpha))
    assert len(s["layouts"]) == 2 and s["focused"] == 0
    launch("new", "alpha", ok=False)
    launch("new", "../escape", ok=False)
    launch("new", "no-base", "--base", "missing", ok=False)
    launch("open", str(alpha), "--request", "must not replay", ok=False)
    launch("open", str(root), ok=False)

    s["panes"] = [s["panes"][1]]
    state.write_text(json.dumps(s))
    s = launch("open", str(alpha))
    assert len(s["layouts"]) == 3
    assert "Explain" not in s["layouts"][-1]
    assert s["session"] == session
    records = list((repo / ".git" / "pi-task").glob("*.json"))
    assert len(records) == 2
    alpha_record = next(json.loads(p.read_text()) for p in records if json.loads(p.read_text())["root"] == str(alpha))
    assert alpha_record["request"] == request
    assert git("status", "--porcelain") == original_status

    library = root / "library"
    subprocess.run(["git", "init", "-q", str(library)], check=True)
    (library / "content").write_text("committed submodule\n")
    subprocess.run(["git", "-C", str(library), "add", "content"], check=True)
    subprocess.run(["git", "-C", str(library), "-c", "user.name=Check", "-c", "user.email=check@example.invalid", "commit", "-qm", "library"], check=True)
    git("-c", "protocol.file.allow=always", "submodule", "add", str(library), "library")
    git("-c", "user.name=Check", "-c", "user.email=check@example.invalid", "commit", "-qm", "add library")
    env["GIT_ALLOW_PROTOCOL"] = "file"
    launch("new", "with-library")
    assert (Path(str(repo) + ".worktrees") / "with-library/library/content").read_text() == "committed submodule\n"
    assert git("status", "--porcelain") == original_status

    if "--live" in sys.argv:
        real_zellij = shutil.which("zellij")
        real_nvim = shutil.which("nvim")
        assert real_zellij and real_nvim, 'live check requires Zellij and Neovim'
        mock.unlink()
        runtime = root / "runtime"
        runtime.mkdir(mode=0o700)
        config = root / "config.kdl"
        config.write_text("session_serialization false\n")
        agent_log = root / "agents.jsonl"
        (commands / "pi").write_text(f'''#!/usr/bin/env python3
import json, os, sys, time
with open({str(agent_log)!r}, 'a') as f:
    f.write(json.dumps(dict(root=os.environ['PI_TASK_ROOT'], pane=os.environ['ZELLIJ_PANE_ID'], args=sys.argv[1:])) + '\\n')
while True: time.sleep(60)
''')
        (commands / "nvim").write_text(f'''#!/usr/bin/env bash
if [ "${{1:-}}" = --server ]; then exec {shlex.quote(real_nvim)} "$@"; fi
exec {shlex.quote(real_nvim)} --headless -u NONE --listen "$XDG_RUNTIME_DIR/nvim.$$.0"
''')
        for tool in ("pi", "nvim"): (commands / tool).chmod(0o755)
        session = f"pi-task-check-{os.getpid()}"
        env.update(XDG_RUNTIME_DIR=str(runtime))
        initial_layout = root / "initial.kdl"
        initial_layout.write_text('layout { pane command="sleep" { args "600"; }; }')

        def native(*args):
            result = subprocess.run([real_zellij, "--session", session, *args],
                                    env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=15)
            assert result.returncode == 0, result.stdout
            return result.stdout

        def native_launch(*args):
            result = subprocess.run(["bash", str(LAUNCHER), "--repo", str(repo), *args],
                                    cwd=repo, env=env, capture_output=True, text=True, timeout=20)
            assert result.returncode == 0, result.stdout + result.stderr

        started = False
        client_pid = None
        try:
            native("--config", str(config), "--new-session-with-layout", str(initial_layout),
                   "attach", "--create-background", session)
            started = True
            # Focus/hide actions need a real client, not just a detached server.
            client_pid, client_fd = pty.fork()
            if client_pid == 0:
                os.execve(real_zellij, [real_zellij, "--config", str(config), "attach", session], env)

            def drain_terminal():
                while True:
                    try:
                        if not os.read(client_fd, 65536): return
                    except OSError as error:
                        if error.errno == errno.EIO: return
                        raise

            threading.Thread(target=drain_terminal, daemon=True).start()
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                if any(line.strip() for line in native("action", "list-clients").splitlines()[1:]): break
                time.sleep(0.1)
            else:
                raise AssertionError('test client did not attach')
            origin = next(p for p in json.loads(native("action", "list-panes", "--json")) if not p["is_plugin"])
            env.update(ZELLIJ="1", ZELLIJ_SESSION_NAME=session, ZELLIJ_PANE_ID=str(origin["id"]))
            (repo / ".git" / "pi-task" / "session").write_text(session + "\n")
            native_launch("open", str(alpha))
            native_launch("new", "gamma", "--request", request)
            before = json.loads(native("action", "list-panes", "--json", "--all"))
            native_launch("open", str(alpha))
            after = json.loads(native("action", "list-panes", "--json", "--all"))
            assert len(before) == len(after), 'reopening duplicated a live workspace'
            gamma = Path(str(repo) + ".worktrees") / "gamma"
            module = LAUNCHER.parents[1] / "modules/aspects/agents/pi/extensions/tool-guardian/mux.ts"
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                agents = [json.loads(line) for line in agent_log.read_text().splitlines()] if agent_log.exists() else []
                if len(agents) == 2: break
                time.sleep(0.1)
            assert {a["root"] for a in agents} == {str(alpha), str(gamma)}
            for agent in agents:
                if agent["root"] == str(gamma): assert agent["args"] == ["--", request]
                check_env = env | {"ZELLIJ_PANE_ID": agent["pane"], "PI_TASK_ROOT": agent["root"]}
                check_env.pop("NVIM", None)
                target = json.loads(subprocess.check_output([
                    "bun", "-e", f'import {{resolveNvimTarget}} from {json.dumps(str(module))}; console.log(JSON.stringify(resolveNvimTarget()));',
                ], env=check_env, text=True, timeout=15))
                assert target and target["paneId"] != agent["pane"]
                identity = json.loads(subprocess.check_output([
                    real_nvim, "--server", target["socket"], "--remote-expr", "json_encode([$PI_TASK_ROOT, getcwd()])",
                ], env=check_env, text=True, timeout=10))
                assert identity == [agent["root"], agent["root"]]
            print("pi-task: real Zellij layouts, task roots, requests and editor routing passed")
        finally:
            if started: native("kill-session", session)
            if client_pid:
                os.waitpid(client_pid, 0)
                os.close(client_fd)

print("pi-task: isolation, quoting, attachment, reopening and failure checks passed")
