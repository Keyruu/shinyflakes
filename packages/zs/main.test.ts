import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, readlinkSync, renameSync, rmSync, statSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { createServer } from "node:http";
import { dirname, join } from "node:path";
import { afterEach, beforeEach, mock, test } from "node:test";
import { setTimeout as sleep } from "node:timers/promises";
import { fileURLToPath } from "node:url";
import {
  Catalog, agentMarkers, attention, choose, commands, deleteSession, desktopSource, filterCommand, hidePicker,
  githubRepository, gitPreview, key, lastVisit, main, navigation, newSessionName, orderRows, paneIdentity, pullRequestPreview, recordVisit, removeWorktree, renderRow, resurrectableSessions, run, selectedPane, sessionNames, sourceContext, taskRoot, toggleView,
} from "./main.ts";
import type { CommandOptions, CommandResult, LaunchOptions, Pane, Row, RunningCommand } from "./main.ts";

const realCapture = commands.capture;
function pane(id = 1, cwd: string | null = null, extra: Partial<Pane> = {}): Pane {
  return { id, is_plugin: false, tab_id: 10, tab_name: "work", title: "shell", exited: false,
    terminal_command: "fish", pane_cwd: cwd, is_selectable: true, is_floating: false,
    attention: { status: "Idle", seen: true, muted: null }, ...extra };
}

class FakeCLI {
  sessions = new Map<string, Pane[] | null>();
  resurrectable = new Set<string>();
  clients = new Map<string, number>();
  dirs: string[] = [];
  githubResponses: unknown[] = [];
  calls: string[][] = [];
  picks: ([string, string] | null)[] = [];
  windows: { appid: string; id: number; title: string }[] = [];
  launchHandler?: (args: string[], options: LaunchOptions) => RunningCommand;

  async capture(args: string[], options: CommandOptions = {}): Promise<CommandResult> {
    this.calls.push([...args]);
    let code = 0, stdout = "", stderr = "";
    if (["git", "getconf"].includes(args[0])) return realCapture(args, options);
    if (args[0] === "zellij" && args[1] === "list-sessions") {
      stdout = this.sessions.size ? [...this.sessions.keys()].map((name) => args.includes("--short") ? name :
        `${name} [Created 1m ago] ${this.sessions.get(name) === null && this.resurrectable.has(name) ? "(EXITED - attach to resurrect)" : ""}`).join("\n") + "\n" : "";
      if (!this.sessions.size) { code = 1; stderr = "No active zellij sessions found.\n"; }
    } else if (args[0] === "zellij" && args[1] === "delete-session") {
      this.sessions.delete(args.at(-1)!);
    } else if (args[0] === "zellij") {
      const session = args[1].replace(/^--session=/, ""), action = args[3];
      if (action === "list-panes") {
        if (this.sessions.get(session) == null) { code = 1; stderr = "Session not found"; }
        else stdout = JSON.stringify(this.sessions.get(session));
      } else if (action === "list-clients") {
        stdout = "CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n" + Array.from({ length: this.clients.get(session) ?? 0 },
          (_, n) => `${n} terminal_1 fish\n`).join("");
      } else if (action === "switch-session") {
        this.clients.set(session, 0);
        this.clients.set(args.at(-1)!, 1);
        if (this.resurrectable.delete(args.at(-1)!)) this.sessions.set(args.at(-1)!, []);
      } else if (action === "hide-floating-panes") code = 2;
      else assert.equal(action, "focus-pane-id", `Unexpected Zellij mutation: ${args}`);
    } else if (args[0] === "gh") {
      assert.equal(options.timeout, 3000);
      assert.ok(args.includes("60s"));
      assert.ok(this.githubResponses.length, "Unexpected GitHub request");
      const response = this.githubResponses.shift();
      if (response === null) { code = 1; stderr = "fixture: auth/network failure"; }
      else stdout = JSON.stringify(response);
    } else if (args[0] === "zoxide") stdout = this.dirs.join("\n");
    else if (["fzf", "vicinae"].includes(args[0])) {
      const choice = this.picks.shift();
      if (!choice) code = 130;
      else {
        const [pressed, substring] = choice;
        const selected = options.input!.split("\n").find((line) => line.includes(substring));
        assert.ok(selected, `No row matching ${substring}: ${options.input}`);
        stdout = (args[0] === "fzf" ? pressed + "\n" : "") + selected + "\n";
      }
    } else if (args[0] === "mmsg" && args[1] === "get") stdout = JSON.stringify({ clients: this.windows });
    else assert.deepEqual(args.slice(0, 2), ["mmsg", "dispatch"], `Unexpected external command: ${args}`);
    return { code, stdout, stderr };
  }
  mutations(): string[][] {
    return this.calls.filter((c) => (c[0] === "zellij" && (c[1] === "delete-session" ||
      (c[2] === "action" && !["list-panes", "list-clients"].includes(c[3])))) || (c[0] === "mmsg" && c[1] === "dispatch"));
  }
}

let root: string, originalCwd: string, originalEnv: NodeJS.ProcessEnv, fake: FakeCLI;
beforeEach(() => {
  root = mkdtempSync(join(tmpdir(), "zs-tests-"));
  originalCwd = process.cwd();
  originalEnv = { ...process.env };
  for (const name of Object.keys(process.env)) delete process.env[name];
  Object.assign(process.env, { PATH: originalEnv.PATH, HOME: root, XDG_CACHE_HOME: join(root, "cache"),
    GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_NOSYSTEM: "1" });
  process.chdir(root);
  fake = new FakeCLI();
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => fake.capture(args, options));
  mock.method(commands, "launch", (args: string[], options: LaunchOptions) => {
    assert.ok(fake.launchHandler, `Unexpected terminal launch: ${args}`);
    return fake.launchHandler(args, options);
  });
});
afterEach(() => {
  mock.restoreAll();
  process.chdir(originalCwd);
  for (const name of Object.keys(process.env)) delete process.env[name];
  Object.assign(process.env, originalEnv);
  rmSync(root, { recursive: true, force: true });
});
async function filterInput(input: string, query: string): Promise<CommandResult> {
  const path = join(root, "filter rows 'quoted'");
  writeFileSync(path, input);
  return realCapture(["bash", "--noprofile", "--norc", "-c", filterCommand(path).replace("{q}", '"$1"'), "zs-filter", query]);
}
async function git(path: string, ...args: string[]): Promise<string> { return (await run(["git", "-C", path, ...args]))!.trim(); }
async function repo(name = "repo with spaces"): Promise<string> {
  const path = join(root, name);
  mkdirSync(path, { recursive: true });
  await git(path, "init", "-b", "main");
  await git(path, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-m", "fixture");
  return path;
}
async function source(session = "source") {
  fake.sessions.set(session, [pane(9, root, { title: "zs", is_floating: true })]);
  fake.clients.set(session, 1);
  Object.assign(process.env, { ZELLIJ_SESSION_NAME: session, ZELLIJ_PANE_ID: "9" });
  return (await sourceContext())!;
}
function target(session = "target with spaces", id = 2): Row {
  const p = pane(id, root);
  fake.sessions.set(session, [p]);
  fake.clients.set(session, 0);
  return { id: "target", label: "target", kind: "workspace", path: root, session, pane: id, identity: paneIdentity(p) };
}
function marker(extra: Record<string, unknown> = {}): string {
  const value = { pid: process.pid, cwd: root, status: "working", sessionId: "conversation-1", sessionFile: "/transcript",
    zellijSession: "target", zellijPaneId: "2", ...extra };
  const directory = join(root, "cache", "pi-herd");
  mkdirSync(directory, { recursive: true });
  const file = join(directory, `${value.pid}.json`);
  writeFileSync(file, JSON.stringify(value));
  return file;
}

test("groups Git identity and multiple agents", async () => {
  const main = await repo(), other = await repo("other/repo with spaces"), tree = join(root, "worktree space");
  await git(main, "worktree", "add", "-b", "task/example", tree);
  fake.dirs = [tree, main, other];
  fake.sessions.set("project", [
    pane(1, tree, { terminal_command: "pi", program_status: [{ app: "pi" }], attention: { status: "Working", source: "ProgramStatus" } }),
    pane(2, tree, { terminal_command: "pi", program_status: [{ app: "pi" }], attention: { status: "NeedsYou", source: "ProgramStatus" } }),
  ]);
  const catalog = await new Catalog().discover();
  assert.equal(catalog.repos.size, 2);
  assert.equal(catalog.rows.filter((r) => r.kind === "agent").length, 2);
  const trees = catalog.rows.filter((r) => r.kind === "worktree");
  assert.equal(trees.length, 3);
  assert.equal(trees.find((r) => r.path === tree)!.branch, "task/example");
  assert.equal(await newSessionName(main), await newSessionName(other));
  assert.equal(catalog.rows.length, new Set(catalog.rows.map((r) => r.id)).size);
  assert.deepEqual(fake.mutations(), []);
});

test("detached worktree and nested cwd", async () => {
  const main = await repo(), tree = join(root, "detached");
  await git(main, "worktree", "add", "--detach", tree);
  mkdirSync(join(tree, "nested"));
  const catalog = new Catalog();
  assert.equal(await catalog.locate(join(tree, "nested")), tree);
  assert.ok(catalog.locations.get(tree)!.branch.startsWith("detached "));
});

test("attention buckets take priority, with recency rather than rank inside each bucket", () => {
  const rows: Row[] = [0, 1, 2, 3, 4, 5, 6].map((rank) => ({ id: String(rank), label: String(rank), kind: "agent", session: "fixture", pane: rank, rank }));
  let now = Date.now() - 10000;
  mock.method(Date, "now", () => now);
  for (const row of [...rows].reverse()) { now += 100; recordVisit(row); }
  const before = JSON.stringify(rows);
  assert.deepEqual(orderRows(rows).map((r) => r.rank), [5, 6, 4, 0, 1, 2, 3]);
  assert.equal(JSON.stringify(rows), before);
});

test("seen/muted results and Pi fallback never become unread through sorting", () => {
  const states = [
    { status: "Done", seen: true }, { status: "Failed", seen: true }, { status: "NeedsYou", muted: "Pane" },
    { status: "Done", seen: false }, { status: "Idle" },
  ];
  const rows: Row[] = states.map((native, i) => {
    const [rank, status] = attention({ attention: native }, i === 4 ? { status: "waiting" } : undefined);
    return { id: String(i), label: status, kind: "agent", session: "fixture", pane: i, rank, status };
  });
  recordVisit(rows[0]);
  assert.deepEqual(orderRows(rows).map((r) => r.id), ["4", "3", "0", "1", "2"]);
  assert.match(rows[4].status!, /seen unknown/);
  assert.equal(states[0].seen, true);
});

test("repo/worktree/agent groups stay intact while priority and visits propagate upwards", async () => {
  const a = await repo("a"), b = await repo("b"), z = await repo("z"), tree = join(root, "urgent");
  await git(z, "worktree", "add", "-b", "urgent", tree);
  fake.dirs = [a, b, z, tree];
  fake.sessions.set("work", [
    pane(1, tree, { program_status: [{ app: "pi" }], attention: { status: "NeedsYou" } }),
    pane(2, tree, { program_status: [{ app: "pi" }], attention: { status: "Failed", seen: false } }),
  ]);
  let now = Date.now() - 10000;
  mock.method(Date, "now", () => now);
  recordVisit({ id: "b", label: "b", path: b });
  now += 100;
  recordVisit({ id: "agent", label: "agent", path: tree, session: "work", pane: 2 });
  now += 100;
  recordVisit({ id: "z", label: "z", path: z });
  const catalog = await new Catalog().discover(), rows = catalog.rows;
  assert.deepEqual(rows.filter((r) => r.kind === "repo").map((r) => r.path), [z, b, a]);
  const common = rows[0].repo;
  const group = rows.filter((r) => r.repo === common);
  assert.deepEqual(rows.slice(0, group.length), group);
  assert.deepEqual(group.filter((r) => r.kind === "worktree").map((r) => r.path), [tree, z]);
  assert.deepEqual(group.filter((r) => r.kind === "agent").map((r) => r.pane), [2, 1]);
  assert.deepEqual(fake.mutations(), []);
});

test("unmapped sessions inherit attention and directories participate in recency ordering", () => {
  const rows: Row[] = [
    { id: "cold", kind: "directory", label: "cold", path: join(root, "cold") },
    { id: "recent", kind: "directory", label: "recent", path: join(root, "recent") },
    { id: "session", kind: "session", label: "session", session: "unmapped" },
    { id: "agent", kind: "agent", label: "agent", session: "unmapped", pane: 1, rank: 4 },
  ];
  recordVisit(rows[1]);
  assert.deepEqual(orderRows(rows).map((r) => r.id), ["session", "agent", "recent", "cold"]);
  assert.deepEqual(orderRows([rows[1], rows[0]]).map((r) => r.id), ["recent", "cold"]);
  assert.deepEqual(orderRows([{ id: "first", label: "z", rank: 0 }, { id: "second", label: "a", rank: 3 }]).map((r) => r.id), ["first", "second"]);
});

test("visit files contain only private timestamp markers and use the default cache fallback", () => {
  delete process.env.XDG_CACHE_HOME;
  const row: Row = { id: "private", kind: "agent", label: "secret title", path: root, session: "secret session", pane: 1 };
  recordVisit(row);
  const directory = join(root, ".cache", "zs", "visits");
  const files = readdirSync(directory);
  assert.equal(files.length, 3);
  assert.equal(statSync(directory).mode & 0o777, 0o700);
  for (const file of files) {
    assert.match(file, /^[a-f0-9]{16}$/);
    assert.equal(statSync(join(directory, file)).mode & 0o777, 0o600);
    assert.equal(readFileSync(join(directory, file), "utf8"), "");
  }
  assert.ok(lastVisit(row) > 0);
  assert.ok(lastVisit({ ...row, kind: "worktree" }) > 0);
  assert.ok(lastVisit({ ...row, kind: "session" }) > 0);
  recordVisit(row);
  assert.equal(readdirSync(directory).length, 3);
});

test("independent picker processes preserve visits to different destinations", async () => {
  const rows: Row[] = ["one", "two"].map((name) => ({ id: name, label: name, kind: "directory", path: join(root, name) }));
  const module = fileURLToPath(new URL("main.ts", import.meta.url));
  const results = await Promise.all(rows.map((row) => realCapture([process.execPath, "--experimental-strip-types", "--input-type=module", "-e",
    `import { recordVisit } from ${JSON.stringify(module)}; recordVisit(${JSON.stringify(row)});`])));
  for (const result of results) assert.equal(result.code, 0, result.stderr);
  for (const row of rows) assert.ok(lastVisit(row) > 0);
});

test("missing/future/symlink visit entries are ignored without touching their targets", () => {
  const row: Row = { id: "test", label: "test", kind: "directory", path: root };
  assert.equal(lastVisit(row), 0);
  const directory = join(root, "cache", "zs", "visits"), entry = join(directory, key("checkout", root));
  mkdirSync(directory, { recursive: true });
  writeFileSync(entry, "");
  const future = new Date(Date.now() + 86400000);
  utimesSync(entry, future, future);
  assert.equal(lastVisit(row), 0);
  rmSync(entry);
  const sentinel = join(root, "keep");
  writeFileSync(sentinel, "do not touch");
  symlinkSync(sentinel, entry);
  const errors = mock.method(console, "error", () => {});
  assert.equal(lastVisit(row), 0);
  recordVisit(row);
  assert.equal(readFileSync(sentinel, "utf8"), "do not touch");
  assert.equal(errors.mock.calls.length, 1);
});

test("only successful navigation records visits, not rejected destinations", async () => {
  const origin = await source(), row = target();
  fake.clients.set(row.session!, 1);
  await assert.rejects(navigation(row, origin), /second attachment/);
  assert.equal(lastVisit(row), 0);
  fake.clients.set(row.session!, 0);
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args.includes("switch-session")) assert.equal(lastVisit(row), 0);
    return fake.capture(args, options);
  });
  await navigation(row, origin);
  assert.ok(lastVisit(row) > 0);
  assert.ok(lastVisit({ ...row, kind: "worktree" }) > 0);
});

test("new terminal without an explicit pane records arrival before the terminal exits", async () => {
  const row: Row = { id: "new", label: "new", kind: "directory", path: root };
  const destination = await newSessionName(root);
  let waited = false;
  fake.launchHandler = () => {
    assert.equal(lastVisit(row), 0);
    fake.sessions.set(destination, [pane(1, root)]);
    fake.clients.set(destination, 1);
    return { poll: () => undefined, wait: async () => { waited = true; assert.ok(lastVisit(row) > 0); return { code: 0 }; }, release: () => {} };
  };
  await navigation(row, null);
  assert.ok(waited);
});

test("unwritable visit cache warns without turning successful navigation into a failure", async () => {
  const origin = await source(), row = target();
  const blocked = join(root, "not-a-directory");
  writeFileSync(blocked, "keep");
  process.env.XDG_CACHE_HOME = blocked;
  const errors = mock.method(console, "error", () => {});
  await navigation(row, origin);
  assert.equal(errors.mock.calls.length, 1);
  assert.match(String(errors.mock.calls[0].arguments[0]), /navigation succeeded/);
  assert.equal(readFileSync(blocked, "utf8"), "keep");
});

test("native seen and muted attention are not unread", () => {
  for (const status of ["Done", "done", "Failed", "NewOutput"]) {
    const [rank, label] = attention({ attention: { status, seen: true } });
    assert.equal(rank, 0);
    assert.doesNotMatch(label, /unread/);
  }
  const [rank, label] = attention({ attention: { status: "NeedsYou", muted: "Pane" } });
  assert.equal(rank, 0);
  assert.match(label, /muted/);
  assert.match(attention({ attention: { status: "Done", seen: false } })[1], /unread/);
});

test("raw done does not override acknowledged native state", () => {
  const [rank, label] = attention(pane(1, null, { program_status: [{ app: "pi", state: "Done" }] }), { status: "working" });
  assert.equal(rank, 0);
  assert.doesNotMatch(label, /unread|working/);
});

test("fallback has no seen claim", () => {
  const [rank, label] = attention(pane(), { status: "waiting" });
  assert.equal(rank, 6);
  assert.match(label, /Pi waiting · seen unknown/);
  assert.doesNotMatch(label, /unread/);
  assert.match(attention({}, { status: "idle" })[1], /Pi idle/);
});

test("live marker pins checkout and conversation identity is revalidated", async () => {
  const path = await repo(), file = marker({ taskRoot: path });
  fake.sessions.set("target", [pane(2, root, { terminal_command: "pi" })]);
  const agent = (await new Catalog().discover()).rows.find((r) => r.kind === "agent")!;
  assert.equal(agent.path, path);
  await selectedPane(agent);
  const saved = JSON.parse(readFileSync(file, "utf8"));
  saved.sessionId = "conversation-2";
  writeFileSync(file, JSON.stringify(saved));
  await assert.rejects(selectedPane(agent), /identity changed/);
});

test("stale, malformed and mismatched markers are ignored", async () => {
  const file = marker();
  utimesSync(file, 1, 1);
  assert.deepEqual(await agentMarkers(), []);
  writeFileSync(file, "{broken");
  assert.deepEqual(await agentMarkers(), []);
  writeFileSync(file, JSON.stringify({ pid: process.pid + 1 }));
  assert.deepEqual(await agentMarkers(), []);
});

test("mixed mapped/unmapped session keeps both targets", async () => {
  const path = await repo();
  fake.sessions.set("mixed", [pane(1, path), pane(2, null, { tab_id: 11 })]);
  const rows = (await new Catalog().discover()).rows;
  assert.deepEqual(new Set(rows.filter((r) => r.pane !== undefined).map((r) => r.pane)), new Set([1, 2]));
});

test("labels sanitize controls without changing identity", () => {
  const row = new Catalog().addRow("session", "bad\x1b]title\n\t\u202e", { session: "space and 'quote'" });
  assert.doesNotMatch(row.label, /[\x1b\n\t\u202e]/);
  assert.equal(row.session, "space and 'quote'");
});

test("task launch path is not a title", () => {
  const p = pane(1, null, { terminal_command: "env PI_TASK_ROOT=/a path/repo's checkout PI_TASK_REVIEW_STATE=/state pi" });
  assert.equal(taskRoot(p), "/a path/repo's checkout");
  assert.equal(taskRoot(pane(1, null, { title: "PI_TASK_ROOT=/wrong" })), null);
});

test("same-session exact focus and idempotent cleanup", async () => {
  const origin = await source(), p = pane(2, root);
  fake.sessions.get("source")!.push(p);
  await navigation({ id: "p2", label: "p2", session: "source", pane: 2, identity: paneIdentity(p) }, origin);
  assert.deepEqual(fake.mutations().at(-1), ["zellij", "--session=source", "action", "focus-pane-id", "terminal_2"]);
  await hidePicker(origin);
  assert.equal(fake.mutations().filter((c) => c.includes("hide-floating-panes")).length, 1);
});

test("cross-session focus uses exact name and hides only source", async () => {
  const origin = await source(), row = target("target ' $(false) with spaces");
  await navigation(row, origin);
  assert.deepEqual(fake.mutations().at(-1), ["zellij", "--session=source", "action", "switch-session", "--pane-id", "terminal_2", "--", row.session]);
  assert.equal(fake.mutations()[0].at(-1), "10");
  await hidePicker(origin);
  assert.equal(fake.mutations().length, 2);
});

test("refuses second client without mutations", async () => {
  const origin = await source(), row = target();
  fake.clients.set(row.session!, 1);
  await assert.rejects(navigation(row, origin), /second attachment/);
  assert.deepEqual(fake.mutations(), []);
});

test("refuses unknown or multiple source clients", async () => {
  const origin = await source();
  fake.clients.set("source", 2);
  await assert.rejects(sourceContext());
  await assert.rejects(navigation(target(), origin));
  assert.deepEqual(fake.mutations(), []);
});

test("closed or changed pane never creates a phantom session", async () => {
  const row = target();
  fake.sessions.get(row.session!)![0].terminal_command = "different";
  await assert.rejects(selectedPane(row), /changed or closed/);
  fake.sessions.set(row.session!, null);
  fake.resurrectable.add(row.session!);
  await assert.rejects(navigation(row, null), /implicit creation/);
  assert.deepEqual(fake.mutations(), []);
});

test("native saved-session classification keeps exact names and ignores live or malformed markers", async () => {
  const saved = "saved ' $(false) with spaces";
  fake.sessions.set(saved, null);
  fake.resurrectable.add(saved);
  fake.sessions.set("unreachable", null);
  fake.sessions.set("live [Created 1m ago] (EXITED - attach to resurrect)", []);
  assert.deepEqual(await resurrectableSessions(), new Set([saved]));
  mock.method(commands, "capture", async () => ({ code: 0, stdout: "unknown (EXITED - attach to resurrect)\n", stderr: "" }));
  assert.deepEqual(await resurrectableSessions(), new Set());
  mock.method(commands, "capture", async () => ({ code: 1, stdout: "", stderr: "permission denied" }));
  assert.deepEqual(await resurrectableSessions(), new Set());
});

test("Enter on a saved session resurrects directly without reapplying a layout or targeting an old pane", async () => {
  await source();
  const name = "saved ' $(false) with spaces";
  fake.sessions.set(name, null);
  fake.resurrectable.add(name);
  fake.picks = [["", "resurrectable"]];
  await main([]);
  assert.deepEqual(fake.mutations().at(-1), ["zellij", "--session=source", "action", "switch-session", "--", name]);
  assert.equal(fake.calls.filter((c) => c[0] === "fzf").length, 1);
  assert.ok(!fake.calls.some((c) => c[1] === `--session=${name}` && c.includes("list-clients")));
  assert.ok(lastVisit({ id: key("session", undefined, name, undefined), label: name, kind: "session", session: name }) > 0);
});

for (const dmenu of [false, true]) {
  test(`saved session ${dmenu ? "desktop" : "terminal"} launch uses native attach without forcing commands`, async () => {
    const name = "saved session", row: Row = { id: "saved", label: name, kind: "session", session: name };
    fake.sessions.set(name, null);
    fake.resurrectable.add(name);
    fake.launchHandler = (args, options) => {
      const prefix = dmenu ? ["footclient", "--client-environment", "-D", root] : [];
      assert.deepEqual(args, [...prefix, "zellij", "attach", name]);
      assert.equal(options.env.ZELLIJ_SESSION_NAME, undefined);
      fake.sessions.set(name, []);
      fake.clients.set(name, 1);
      return { poll: () => undefined, wait: async () => ({ code: 0 }), release: () => {} };
    };
    await navigation(row, null, dmenu);
    assert.ok(lastVisit(row) > 0);
    assert.deepEqual(fake.mutations(), []);
  });
}

test("resurrection reuses only a verified desktop window", async () => {
  target("attached");
  fake.clients.set("attached", 1);
  fake.windows = [{ appid: "footclient", id: 4, title: "attached | shell" }];
  fake.sessions.set("saved", null);
  fake.resurrectable.add("saved");
  await navigation({ id: "saved", label: "saved", kind: "session", session: "saved" }, null, true);
  assert.deepEqual(fake.mutations(), [
    ["zellij", "--session=attached", "action", "switch-session", "--", "saved"],
    ["mmsg", "dispatch", "focusid,4"],
  ]);
});

test("a stale resurrectable label never authorizes restoring an unreachable session", async () => {
  const origin = await source();
  fake.sessions.set("unavailable", null);
  await assert.rejects(navigation({ id: "saved", label: "saved", status: "resurrectable", kind: "session", session: "unavailable" }, origin), /not confirmed as resurrectable/);
  assert.deepEqual(fake.mutations(), []);
});

for (const change of ["disappeared", "restarted"]) {
  test(`resurrection refuses a saved session that ${change} during preflight`, async () => {
    const origin = await source();
    fake.sessions.set("saved", null);
    fake.resurrectable.add("saved");
    let inspections = 0;
    mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
      if (args[1] === "--session=saved" && args.includes("list-panes") && ++inspections === 2) {
        fake.resurrectable.delete("saved");
        if (change === "disappeared") fake.sessions.delete("saved");
        else { fake.sessions.set("saved", []); fake.clients.set("saved", 1); }
      }
      return fake.capture(args, options);
    });
    await assert.rejects(navigation({ id: "saved", label: "saved", kind: "session", session: "saved" }, origin), /changed or disappeared/);
    assert.deepEqual(fake.mutations(), []);
  });
}

test("new session uses a readable directory name and the Pi-starting project layout", async () => {
  const origin = await source();
  await navigation({ id: "directory", label: "directory", kind: "directory", path: root }, origin);
  const command = fake.mutations().at(-1)!;
  assert.equal(command.at(-1), await newSessionName(root));
  assert.ok(command.includes(root));
  assert.equal(command[command.indexOf("--layout") + 1], "project");
  assert.ok(!command.includes("--layout-string"));
});

test("new-session collision refused", async () => {
  fake.sessions.set(await newSessionName(root), null);
  await assert.rejects(navigation({ id: "dir", label: "dir", path: root }, null), /already uses/);
  assert.deepEqual(fake.mutations(), []);
});

test("Enter on a linked branch restores its exact-name saved session rather than creating another", async () => {
  const origin = await source(), path = await repo("app"), linked = join(root, "linked");
  await git(path, "worktree", "add", "-b", "task/fix-picker", linked);
  fake.dirs = [linked];
  const name = await newSessionName(linked);
  fake.sessions.set(name, null);
  fake.resurrectable.add(name);
  fake.picks = [["", "⎇ task/fix-picker"]];
  await main([]);
  assert.deepEqual(fake.mutations().at(-1), ["zellij", "--session=source", "action", "switch-session", "--", name]);
  assert.equal(fake.calls.filter((c) => c[0] === "fzf").length, 1);
  assert.ok(!fake.mutations().at(-1)!.includes("--layout"));
  assert.ok(lastVisit({ id: key("worktree", linked, undefined, undefined), label: "branch", kind: "worktree", path: linked }) > 0);
});

test("main checkout restores its saved repository-name session", async () => {
  await source();
  const path = await repo("app");
  fake.dirs = [path];
  fake.sessions.set("app", null);
  fake.resurrectable.add("app");
  fake.picks = [["", "⎇ main"]];
  await main([]);
  assert.deepEqual(fake.mutations().at(-1), ["zellij", "--session=source", "action", "switch-session", "--", "app"]);
});

for (const dmenu of [false, true]) {
  test(`saved branch ${dmenu ? "desktop" : "terminal"} launch uses attach, not a fresh project layout`, async () => {
    const path = await repo("app"), linked = join(root, "linked");
    await git(path, "worktree", "add", "-b", "task/recover", linked);
    const catalog = new Catalog();
    await catalog.locate(linked);
    catalog.buildRows();
    const row = catalog.rows.find((r) => r.kind === "worktree" && r.path === linked)!;
    const name = await newSessionName(linked);
    fake.sessions.set(name, null);
    fake.resurrectable.add(name);
    fake.launchHandler = (args, options) => {
      const prefix = dmenu ? ["footclient", "--client-environment", "-D", linked] : [];
      assert.deepEqual(args, [...prefix, "zellij", "attach", name]);
      assert.equal(options.cwd, linked);
      fake.sessions.set(name, []);
      fake.clients.set(name, 1);
      return { poll: () => undefined, wait: async () => ({ code: 0 }), release: () => {} };
    };
    await navigation(row, null, dmenu);
    assert.ok(lastVisit(row) > 0);
  });
}

test("a saved name shared by two branches refuses to resurrect either checkout", async () => {
  const path = await repo("app"), first = join(root, "first"), second = join(root, "second");
  await git(path, "worktree", "add", "-b", "task/fix", first);
  await git(path, "worktree", "add", "-b", "task-fix", second);
  const catalog = new Catalog();
  await catalog.locate(second);
  catalog.buildRows();
  const row = catalog.rows.find((r) => r.kind === "worktree" && r.path === second)!;
  const name = await newSessionName(second);
  fake.sessions.set(name, null);
  fake.resurrectable.add(name);
  await assert.rejects(navigation(row, null), /ambiguous/);
  assert.deepEqual(fake.mutations(), []);
});

test("saved branch name with changed checkout or unverified session remains a collision", async () => {
  const path = await repo("app"), linked = join(root, "linked");
  await git(path, "worktree", "add", "-b", "task/recover", linked);
  const catalog = new Catalog();
  await catalog.locate(linked);
  catalog.buildRows();
  const row = catalog.rows.find((r) => r.kind === "worktree" && r.path === linked)!;
  const name = await newSessionName(linked);
  fake.sessions.set(name, null);
  await assert.rejects(navigation(row, null), /already uses/);
  fake.resurrectable.add(name);
  await git(linked, "checkout", "-b", "task/other");
  await assert.rejects(navigation(row, null), /Checkout changed/);
  assert.deepEqual(fake.mutations(), []);
});

test("saved branch that becomes live during preflight does not switch", async () => {
  const origin = await source(), path = await repo("app"), linked = join(root, "linked");
  await git(path, "worktree", "add", "-b", "task/recover", linked);
  const catalog = new Catalog();
  await catalog.locate(linked);
  catalog.buildRows();
  const row = catalog.rows.find((r) => r.kind === "worktree" && r.path === linked)!;
  const name = await newSessionName(linked);
  fake.sessions.set(name, null);
  fake.resurrectable.add(name);
  let inspections = 0;
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args[1] === `--session=${name}` && args.includes("list-panes") && ++inspections === 2) {
      fake.resurrectable.delete(name);
      fake.sessions.set(name, []);
      fake.clients.set(name, 1);
    }
    return fake.capture(args, options);
  });
  await assert.rejects(navigation(row, origin), /changed or disappeared/);
  assert.deepEqual(fake.mutations(), []);
});

test("main, linked and detached worktrees get readable role-aware names", async () => {
  const path = await repo("shinyflakes"), linked = join(root, "linked"), detached = join(root, "detached-checkout");
  await git(path, "worktree", "add", "-b", "task/fix-picker", linked);
  await git(path, "worktree", "add", "--detach", detached);
  assert.equal(await newSessionName(path), "shinyflakes");
  assert.equal(await newSessionName(linked), "shinyflakes--task-fix-picker");
  assert.equal(await newSessionName(detached), "shinyflakes--detached-checkout");
  await git(path, "checkout", "-b", "feature/on-primary");
  assert.equal(await newSessionName(path), "shinyflakes");
});

test("bare repositories do not mistake their first linked worktree for the main checkout", async () => {
  const path = await repo("origin"), bare = join(root, "project.git"), linked = join(root, "checkout");
  await git(root, "clone", "--bare", path, bare);
  await git(bare, "worktree", "add", "-b", "task/bare", linked);
  assert.equal(await newSessionName(linked), "project--task-bare");
});

test("readable-name collisions never attach a different worktree", async () => {
  const path = await repo("app"), first = join(root, "first"), second = join(root, "second");
  await git(path, "worktree", "add", "-b", "task/fix", first);
  await git(path, "worktree", "add", "-b", "task-fix", second);
  const name = await newSessionName(first);
  assert.equal(await newSessionName(second), name);
  fake.sessions.set(name, [pane(1, first)]);
  await assert.rejects(navigation({ id: "second", label: "second", kind: "worktree", path: second }, null), /already uses/);
  assert.deepEqual(fake.mutations(), []);
});

test("long readable session names retain both components within the socket name budget", async () => {
  const path = await repo("repository" + "x".repeat(50)), linked = join(root, "linked");
  await git(path, "worktree", "add", "-b", "task/" + "y".repeat(70), linked);
  assert.equal((await newSessionName(path)).length, 40);
  const name = await newSessionName(linked);
  assert.match(name, /^repositoryx+--task-y+$/);
  assert.equal(name.length, 53);
});

for (const dmenu of [false, true]) {
  test(`new linked-worktree ${dmenu ? "desktop" : "terminal"} launch uses project`, async () => {
    const path = await repo("app"), linked = join(root, "linked");
    await git(path, "worktree", "add", "-b", "task/ui", linked);
    fake.launchHandler = (args, options) => {
      const prefix = dmenu ? ["footclient", "--client-environment", "-D", linked] : [];
      assert.deepEqual(args, [...prefix, "zellij", "--session=app--task-ui", "--new-session-with-layout", "project"]);
      assert.equal(options.cwd, linked);
      fake.sessions.set("app--task-ui", [pane(1, linked)]);
      fake.clients.set("app--task-ui", 1);
      return { poll: () => undefined, wait: async () => { assert.equal(dmenu, false); return { code: 0 }; }, release: () => {} };
    };
    await navigation({ id: "linked", label: "linked", kind: "worktree", path: linked }, null, dmenu);
  });
}

test("reusing an existing hashed session does not rename it or reapply project", async () => {
  const origin = await source(), row = target("existing-deadbeef0123");
  await navigation(row, origin);
  const command = fake.mutations().at(-1)!;
  assert.equal(command.at(-1), "existing-deadbeef0123");
  assert.ok(!command.includes("--layout") && !command.includes("--new-session-with-layout"));
});

test("desktop never chooses arbitrary window", async () => {
  target("attached");
  fake.clients.set("attached", 1);
  fake.windows = [{ appid: "footclient", id: 4, title: "unrelated" }];
  await assert.rejects(desktopSource(), /identify/);
  fake.windows[0].title = "attached | shell";
  assert.deepEqual(await desktopSource(), ["attached", "4"]);
  fake.windows.push({ ...fake.windows[0] });
  await assert.rejects(desktopSource());
  assert.deepEqual(fake.mutations(), []);
});

test("dmenu reuses single verified window", async () => {
  target("attached");
  fake.clients.set("attached", 1);
  const row = target();
  fake.windows = [{ appid: "footclient", id: 4, title: "attached | shell" }];
  await navigation(row, null, true);
  assert.ok(fake.mutations()[0].includes("switch-session"));
  assert.deepEqual(fake.mutations().at(-1), ["mmsg", "dispatch", "focusid,4"]);
});

test("cancel only hides own layer and never closes title matches", async () => {
  await source();
  fake.sessions.get("source")!.push(pane(44, root, { title: "zs", tab_id: 55 }));
  await main([]);
  assert.equal(fake.mutations().length, 1);
  assert.ok(fake.mutations()[0].includes("hide-floating-panes"));
  assert.equal(fake.mutations()[0].at(-1), "10");
});

test("main fzf selection focuses and cleans up", async () => {
  await source();
  fake.sessions.get("source")!.push(pane(2, root));
  fake.picks = [["", root]];
  await main([]);
  assert.equal(fake.mutations().at(-1)!.at(-1), "terminal_2");
  assert.equal(fake.mutations().filter((c) => c.includes("hide-floating-panes")).length, 1);
});

async function workspaceWithAgents() {
  const path = await repo();
  fake.dirs = [path];
  await source();
  fake.sessions.get("source")!.push(
    pane(2, path, { title: "editor", is_focused: true }),
    pane(3, path, { title: "urgent agent", program_status: [{ app: "pi" }], attention: { status: "NeedsYou" } }),
    pane(4, path, { title: "other agent", program_status: [{ app: "pi" }], attention: { status: "Working" } }),
  );
  return path;
}

test("Enter on a worktree with multiple agents restores its hidden editor without another picker", async () => {
  const path = await workspaceWithAgents();
  recordVisit({ id: "editor", label: "editor", path, session: "source", pane: 2 });
  fake.sessions.get("source")![1].is_focused = false;
  fake.sessions.get("source")![2].is_focused = true;
  const catalog = await new Catalog().discover();
  assert.ok(!catalog.targets.some((t) => t.pane === 2));
  fake.picks = [["", "⎇ main"]];
  await main([]);
  assert.equal(fake.calls.filter((c) => c[0] === "fzf").length, 1);
  assert.equal(fake.mutations().at(-1)!.at(-1), "terminal_2");
});

test("without visit history worktree Enter restores the focused pane rather than the urgent agent", async () => {
  await workspaceWithAgents();
  fake.picks = [["", "⎇ main"]];
  await main([]);
  assert.equal(fake.mutations().at(-1)!.at(-1), "terminal_2");
  assert.equal(fake.calls.filter((c) => c[0] === "fzf").length, 1);
});

test("agents are directly selectable beneath their worktree without a drill-down", async () => {
  await workspaceWithAgents();
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args[0] === "fzf") {
      const input = options!.input!;
      assert.ok(input.indexOf("⎇ main") < input.indexOf("urgent agent"));
      assert.ok(input.indexOf("⎇ main") < input.indexOf("other agent"));
      assert.doesNotMatch(input, /editor/);
    }
    return fake.capture(args, options);
  });
  fake.picks = [["", "Pane 4"]];
  await main([]);
  assert.equal(fake.calls.filter((c) => c[0] === "fzf").length, 1);
  assert.equal(fake.mutations().at(-1)!.at(-1), "terminal_4");
});

test("Tab switches the same picker to flat agents without recording a visit", async () => {
  const path = await workspaceWithAgents();
  let picks = 0;
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args[0] !== "fzf") return fake.capture(args, options);
    picks++;
    assert.match(args[args.indexOf("--bind") + 1], /^tab:transform:.*--toggle-view/);
    assert.ok(args.includes("--expect=ctrl-r,ctrl-d,ctrl-x"));
    assert.ok(args.includes("--track") && args.includes("--id-nth=1"));
    const visible = options!.input!.split("\n").map((line) => line.split("\t")[1]).join("\n");
    assert.equal([...visible.matchAll(/repo with spaces/g)].length, 1);
    const directory = dirname(args.find((arg) => arg.startsWith("--listen="))!.slice(9));
    assert.equal(readlinkSync(join(directory, "rows")), "tree");
    assert.match(toggleView(directory), /^change-prompt\(Agents > \)/);
    const flat = readFileSync(join(directory, "rows"), "utf8");
    assert.doesNotMatch(flat, /⎇ main|editor|└─/);
    assert.match(flat, /repo with spaces \/ main · Pane 4/);
    assert.equal(lastVisit({ id: "path", label: "path", kind: "worktree", path }), 0);
    const selected = flat.split("\n").find((line) => line.includes("Pane 4"));
    return { code: 0, stdout: `\n${selected}\n`, stderr: "" };
  });
  await main([]);
  assert.equal(fake.mutations().at(-1)!.at(-1), "terminal_4");
  assert.equal(picks, 1);
});

test("flat agents are globally attention/recency sorted with checkout context once", async () => {
  const one = await repo("one"), two = await repo("two"), linked = join(root, "linked");
  await git(one, "worktree", "add", "-b", "task/fix", linked);
  const agent = (id: number, path: string | null, attention: Record<string, unknown>) =>
    pane(id, path, { program_status: [{ app: "pi" }], attention });
  fake.sessions.set("one-session", [pane(1, one), agent(2, linked, { status: "Working" }), agent(3, linked, { status: "NeedsYou" })]);
  fake.sessions.set("two-session", [agent(4, two, { status: "Failed" }), agent(5, two, { status: "Done" }),
    agent(6, two, { status: "Idle" }), agent(7, two, { status: "NeedsYou", muted: "Pane" }), agent(8, null, { status: "Idle" })]);
  for (const [session, pane, age] of [["one-session", 3, 3000], ["two-session", 4, 2000], ["two-session", 6, 1000]] as const) {
    recordVisit({ id: "visit", label: "visit", kind: "agent", session, pane });
    const time = new Date(Date.now() - age);
    utimesSync(join(root, "cache/zs/visits", key("pane", session, pane)), time, time);
  }
  const catalog = await new Catalog().discover(), agents = catalog.agentRows();
  assert.equal(agents.length, 7);
  assert.deepEqual(agents.slice(0, 4).map((row) => row.pane), [4, 3, 5, 6]);
  const linkedAgent = agents.find((row) => row.pane === 3)!;
  assert.match(renderRow(linkedAgent), /one \/ task\/fix · Pane 3/);
  assert.match(renderRow(agents.find((row) => row.pane === 4)!), /two \/ main · Pane 4/);
  assert.match(renderRow(agents.find((row) => row.pane === 8)!), /Unknown checkout · Pane 8/);
  const original = catalog.rows.find((row) => row.id === linkedAgent.id)!;
  assert.equal(original.display!.detail, "Pane 3");
  assert.deepEqual(linkedAgent.identity, original.identity);
  assert.deepEqual(fake.mutations(), []);
});

test("flat agents remain global when toggled from a repository drill-down", async () => {
  await workspaceWithAgents();
  const other = await repo("other");
  fake.sessions.set("other-session", [pane(7, other, { program_status: [{ app: "pi" }] })]);
  let picks = 0;
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args[0] === "fzf" && ++picks === 2) {
      assert.doesNotMatch(options!.input!, /Pane 7/);
      const directory = dirname(args.find((arg) => arg.startsWith("--listen="))!.slice(9));
      toggleView(directory);
      const selected = readFileSync(join(directory, "rows"), "utf8").split("\n").find((line) => line.includes("other / main · Pane 7"));
      assert.ok(selected);
      return { code: 0, stdout: `\n${selected}\n`, stderr: "" };
    }
    return fake.capture(args, options);
  });
  fake.picks = [["", "repo with spaces"]];
  await main([]);
  assert.deepEqual(fake.mutations().at(-1)!.slice(-4), ["--pane-id", "terminal_7", "--", "other-session"]);
});

test("view toggling rejects unexpected pointers without replacing them", () => {
  const path = join(root, "rows");
  symlinkSync("unexpected", path);
  assert.throws(() => toggleView(root), /Invalid picker view/);
  assert.equal(readlinkSync(path), "unexpected");
});

test("multiple sessions offer session names only, then open the explicitly chosen workspace", async () => {
  const path = await repo();
  fake.dirs = [path];
  await source();
  for (const session of ["session-a", "session-b"]) {
    fake.sessions.set(session, [pane(2, path, { is_focused: true }),
      pane(3, path, { title: "agent one", program_status: [{ app: "pi" }] }),
      pane(4, path, { title: "agent two", program_status: [{ app: "pi" }] })]);
    fake.clients.set(session, 0);
  }
  recordVisit({ id: "recent", label: "recent", path, session: "session-b", pane: 4 });
  let picks = 0;
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args[0] === "fzf" && ++picks === 2) {
      const rows = options!.input!.trimEnd().split("\n");
      assert.equal(rows.length, 2);
      assert.match(rows[0], /session-b/);
      assert.match(rows[1], /session-a/);
      assert.doesNotMatch(options!.input!, /agent one|agent two|Pane \d/);
    }
    return fake.capture(args, options);
  });
  fake.picks = [["", "⎇ main"], ["", "▤ session-a"]];
  await main([]);
  assert.deepEqual(fake.mutations().at(-1)!.slice(-4), ["--pane-id", "terminal_2", "--", "session-a"]);
  assert.equal(picks, 2);
});

test("worktree restoration never follows another branch's newer pane in the same session", async () => {
  const path = await workspaceWithAgents(), other = join(root, "other-checkout");
  await git(path, "worktree", "add", "-b", "other", other);
  fake.sessions.get("source")!.push(pane(5, other, { is_focused: true }));
  recordVisit({ id: "other", label: "other", path: other, session: "source", pane: 5 });
  fake.picks = [["", "⎇ main"]];
  await main([]);
  assert.equal(fake.mutations().at(-1)!.at(-1), "terminal_2");
});

test("session Enter restores its last zs-visited pane without an agent menu", async () => {
  await source();
  fake.sessions.set("unmapped", [
    pane(2, null, { program_status: [{ app: "pi" }] }),
    pane(3, null, { program_status: [{ app: "pi" }], is_focused: true }),
  ]);
  fake.clients.set("unmapped", 0);
  recordVisit({ id: "recent", label: "recent", session: "unmapped", pane: 2 });
  fake.picks = [["", "▤ unmapped"]];
  await main([]);
  assert.deepEqual(fake.mutations().at(-1)!.slice(-4), ["--pane-id", "terminal_2", "--", "unmapped"]);
  assert.equal(fake.calls.filter((c) => c[0] === "fzf").length, 1);
});

test("Esc from repository drill-down returns to the tree overview", async () => {
  await workspaceWithAgents();
  let picks = 0;
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args[0] === "fzf" && ++picks === 3) {
      assert.match(options!.input!, /⎇ main/);
      assert.match(options!.input!, /repo with spaces/);
      assert.doesNotMatch(options!.input!, /editor/);
      assert.match(options!.input!, /urgent agent/);
      assert.match(options!.input!, /other agent/);
    }
    return fake.capture(args, options);
  });
  fake.picks = [["", "repo with spaces"], null, ["", "⎇ main"]];
  await main([]);
  assert.equal(fake.mutations().at(-1)!.at(-1), "terminal_2");
  assert.equal(picks, 3);
});

test("an empty agent view can toggle back without navigating or recording visits", async () => {
  fake.dirs = [await repo()];
  await source();
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args[0] === "fzf") {
      const directory = dirname(args.find((arg) => arg.startsWith("--listen="))!.slice(9));
      toggleView(directory);
      assert.equal(readFileSync(join(directory, "rows"), "utf8"), "");
      assert.match(toggleView(directory), /^change-prompt\(Tree > \)/);
      assert.equal(readFileSync(join(directory, "rows"), "utf8"), options!.input);
    }
    return fake.capture(args, options);
  });
  await main([]);
  assert.ok(fake.mutations().every((c) => c.includes("hide-floating-panes")));
  assert.equal(existsSync(join(root, "cache", "zs", "visits")), false);
});

test("automatic workspace pane restoration retains stale-pane identity checks", async () => {
  await workspaceWithAgents();
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args[0] === "fzf") fake.sessions.get("source")![1].terminal_command = "replaced editor";
    return fake.capture(args, options);
  });
  fake.picks = [["", "⎇ main"]];
  await assert.rejects(main([]), /Selected pane changed or closed/);
  assert.ok(fake.mutations().every((c) => c.includes("hide-floating-panes")));
  assert.equal(existsSync(join(root, "cache", "zs", "visits")), false);
});

test("dmenu worktree entry also restores the workspace without requiring agent selection", async () => {
  await workspaceWithAgents();
  delete process.env.ZELLIJ_SESSION_NAME;
  delete process.env.ZELLIJ_PANE_ID;
  fake.windows = [{ appid: "footclient", id: 7, title: "source" }];
  fake.picks = [["", "├─ main"]];
  await main(["--dmenu"]);
  assert.equal(fake.calls.filter((c) => c[0] === "vicinae").length, 1);
  assert.ok(fake.mutations().some((c) => c.includes("focus-pane-id") && c.at(-1) === "terminal_2"));
  assert.deepEqual(fake.mutations().at(-1), ["mmsg", "dispatch", "focusid,7"]);
});

test("cancelling a multi-session choice never falls back to an arbitrary session", async () => {
  const path = await workspaceWithAgents();
  fake.sessions.set("other", [pane(2, path)]);
  fake.clients.set("other", 0);
  fake.picks = [["", "⎇ main"], null, null];
  await main([]);
  assert.ok(fake.mutations().every((c) => c.includes("hide-floating-panes")));
  assert.equal(existsSync(join(root, "cache", "zs", "visits")), false);
});

test("list does not focus or mark seen", async () => {
  await source();
  const output = mock.method(console, "log", () => {});
  await main(["--list"]);
  assert.deepEqual(fake.mutations(), []);
  assert.doesNotMatch(String(output.mock.calls[0].arguments[0]), /\x1b/);
  assert.equal(existsSync(join(root, "cache", "zs", "visits")), false);
});

test("preview uses snapshot only", async () => {
  const file = join(root, "preview.json");
  writeFileSync(file, JSON.stringify({ opaque: "path: /repo" }));
  const output = mock.method(console, "log", () => {});
  await main(["--preview", file, "opaque"]);
  assert.deepEqual(output.mock.calls[0].arguments, ["path: /repo"]);
  assert.deepEqual(fake.calls, []);
  assert.equal(existsSync(join(root, "cache", "zs", "visits")), false);
});

test("dmenu duplicate labels remain distinct", async () => {
  fake.picks = [["", "2. same"]];
  const [, row] = await choose([{ id: "one", label: "same" }, { id: "two", label: "same" }], true);
  assert.equal(row!.id, "two");
});

async function removableWorktree() {
  const base = await repo(), tree = join(root, "worktree with 'quote'");
  writeFileSync(join(base, "tracked"), "original\n");
  writeFileSync(join(base, ".gitignore"), "ignored\n");
  await git(base, "add", "tracked", ".gitignore");
  await git(base, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-m", "fixture files");
  await git(base, "worktree", "add", "-b", "feature", tree);
  fake.dirs = [base, tree];
  const catalog = await new Catalog().discover();
  const row = catalog.rows.find((r) => r.kind === "worktree" && r.path === tree)!;
  return { base, tree, catalog, row };
}
const removals = () => fake.calls.filter((c) => c[0] === "git" && c.includes("worktree") && c.includes("remove"));

test("confirmed worktree removal keeps the branch, main checkout and all sessions", async () => {
  const { base, tree, catalog, row } = await removableWorktree();
  mock.method(commands, "capture", (args: string[], options?: CommandOptions) => {
    if (args[0] === "fzf") assert.ok(options?.input?.includes(JSON.stringify(tree)));
    return fake.capture(args, options);
  });
  fake.picks = [["", "REMOVE "]];
  await removeWorktree(catalog, row);
  assert.equal(existsSync(tree), false);
  assert.ok(existsSync(base));
  await git(base, "show-ref", "--verify", "refs/heads/feature");
  assert.deepEqual(removals(), [["git", "--git-dir", row.repo!, "worktree", "remove", "--", tree]]);
  assert.deepEqual(fake.mutations(), []);
  assert.ok(!fake.calls.some((c) => c[0] === "gh"));
});

test("worktree removal requires Enter on REMOVE, never Cancel or another action key", async () => {
  const { tree, catalog, row } = await removableWorktree();
  for (const pick of [null, ["", "Cancel"], ["tab", "REMOVE "], ["ctrl-x", "REMOVE "], ["ctrl-d", "REMOVE "], ["ctrl-r", "REMOVE "]] as ([string, string] | null)[]) {
    fake.picks = [pick];
    await removeWorktree(catalog, row);
    assert.ok(existsSync(tree));
    assert.deepEqual(removals(), []);
  }
});

test("main checkout, locked worktrees and non-worktree rows cannot be removed", async () => {
  const { base, tree, catalog, row } = await removableWorktree();
  await assert.rejects(removeWorktree(catalog, catalog.rows.find((r) => r.kind === "repo")!), /Select a Git worktree row/);
  await assert.rejects(removeWorktree(catalog, catalog.rows.find((r) => r.kind === "worktree" && r.path === base)!), /main checkout/);
  await git(base, "worktree", "lock", "--reason", "keep me", tree);
  await assert.rejects(removeWorktree(catalog, row), /locked/);
  assert.deepEqual(removals(), []);
});

for (const state of ["tracked", "staged", "untracked", "ignored"]) {
  test(`${state} files prevent worktree removal without force`, async () => {
    const { tree, catalog, row } = await removableWorktree();
    writeFileSync(join(tree, state === "staged" ? "tracked" : state), "do not discard\n");
    if (state === "staged") await git(tree, "add", "tracked");
    await assert.rejects(removeWorktree(catalog, row), /changes, untracked or ignored/);
    assert.equal(readFileSync(join(tree, state === "staged" ? "tracked" : state), "utf8"), "do not discard\n");
    assert.deepEqual(removals(), []);
  });
}

test("caller cwd and immutable task root protect a worktree even outside Zellij", async () => {
  const { tree, catalog, row } = await removableWorktree();
  process.chdir(tree);
  await assert.rejects(removeWorktree(catalog, row), /current checkout or task root/);
  process.chdir(root);
  process.env.PI_TASK_ROOT = tree;
  await assert.rejects(removeWorktree(catalog, row), /current checkout or task root/);
  assert.deepEqual(removals(), []);
});

test("all live panes, launch bindings and valid agent markers protect occupied worktrees", async () => {
  const { tree, catalog, row } = await removableWorktree();
  for (const p of [pane(1, join(tree, "subdir"), { is_selectable: false }), pane(1, root, {
    terminal_command: `env PI_TASK_ROOT=${tree} PI_TASK_REVIEW_STATE=/state pi`,
  })]) {
    fake.sessions.set("occupied", [p]);
    await assert.rejects(removeWorktree(catalog, row), /occupied by a live Zellij pane/);
  }
  fake.sessions.clear();
  marker({ taskRoot: tree });
  await assert.rejects(removeWorktree(catalog, row), /occupied by a live agent/);
  assert.deepEqual(removals(), []);
});

test("uninspectable sessions and unknown live cwd fail closed for worktree removal", async () => {
  const { catalog, row } = await removableWorktree();
  fake.sessions.set("unavailable", null);
  await assert.rejects(removeWorktree(catalog, row), /Cannot verify session occupancy/);
  fake.sessions.clear();
  fake.sessions.set("unknown", [pane(1, null)]);
  await assert.rejects(removeWorktree(catalog, row), /Cannot verify a live pane's cwd/);
  assert.deepEqual(removals(), []);
});

for (const change of ["dirty", "HEAD", "occupied", "locked", "directory"]) {
  test(`worktree removal rechecks ${change} changes made during confirmation`, async () => {
    const { base, tree, catalog, row } = await removableWorktree();
    mock.method(commands, "capture", async (args: string[], options?: CommandOptions) => {
      if (args[0] === "fzf") {
        if (change === "dirty") writeFileSync(join(tree, "ignored"), "new data\n");
        if (change === "HEAD") await git(tree, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-m", "changed");
        if (change === "occupied") fake.sessions.set("new-session", [pane(1, tree)]);
        if (change === "locked") await git(base, "worktree", "lock", tree);
        if (change === "directory") { renameSync(tree, tree + ".moved"); cpSync(tree + ".moved", tree, { recursive: true }); }
      }
      return fake.capture(args, options);
    });
    fake.picks = [["", "REMOVE "]];
    await assert.rejects(removeWorktree(catalog, row), /changes, untracked or ignored|HEAD changed|occupied|locked|directory changed/);
    assert.ok(existsSync(tree));
    assert.deepEqual(removals(), []);
  });
}

test("Ctrl-X removes a worktree then refreshes without deleting its Zellij session", async () => {
  const { base, tree } = await removableWorktree();
  await source();
  fake.picks = [["ctrl-x", "⎇ feature"], ["", "REMOVE "], null];
  await main([]);
  assert.equal(existsSync(tree), false);
  await git(base, "show-ref", "--verify", "refs/heads/feature");
  assert.ok(fake.calls.find((c) => c[0] === "fzf")!.includes("--expect=ctrl-r,ctrl-d,ctrl-x"));
  assert.ok(fake.sessions.has("source"));
  assert.ok(fake.mutations().every((c) => c.includes("hide-floating-panes")));
  assert.equal(removals().length, 1);
  assert.equal(fake.calls.filter((c) => c[0] === "zoxide").length, 3);
});

test("delete requires Enter confirmation", async () => {
  target();
  const catalog = await new Catalog().discover(), row = catalog.rows.find((r) => r.session)!;
  for (const choice of [["ctrl-d", "DELETE "], ["", "Cancel"]] as [string, string][]) {
    fake.picks = [choice];
    await deleteSession(catalog, row);
    assert.deepEqual(fake.mutations(), []);
  }
  fake.picks = [["", "DELETE "]];
  await deleteSession(catalog, row);
  assert.deepEqual(fake.mutations().at(-1), ["zellij", "delete-session", "--force", "--", row.session]);
});

test("unavailable-session deletion cannot skip client validation", async () => {
  fake.sessions.set("saved", null);
  const catalog = await new Catalog().discover(), row = catalog.rows.find((r) => r.session === "saved")!;
  fake.picks = [["", "DELETE "]];
  await assert.rejects(deleteSession(catalog, row), /Cannot inspect/);
  assert.deepEqual(fake.mutations(), []);
});

test("delete refuses changed session", async () => {
  const row = target(), catalog = await new Catalog().discover();
  fake.sessions.get(row.session!)!.push(pane(3));
  fake.picks = [["", "DELETE "]];
  await assert.rejects(deleteSession(catalog, row), /changed since/);
  assert.deepEqual(fake.mutations(), []);
});

test("external attach refuses a leading-dash session name rather than passing it as an option", async () => {
  fake.sessions.set("-saved", null);
  fake.resurrectable.add("-saved");
  await assert.rejects(navigation({ id: "saved", label: "saved", kind: "session", session: "-saved" }, null), /name starts with '-'/);
  assert.deepEqual(fake.mutations(), []);
});

test("attach sanitizes stale task environment and waits for the terminal", async () => {
  const row = target();
  Object.assign(process.env, { PI_TASK_ROOT: "/stale", PI_TASK_REVIEW_STATE: "/wrong", PI_TASK_SHARED: "1" });
  let waited = false, released = false;
  fake.launchHandler = (args, options) => {
    assert.ok(!("PI_TASK_ROOT" in options.env) && !("PI_TASK_REVIEW_STATE" in options.env));
    assert.deepEqual(args, ["zellij", "attach", row.session]);
    fake.clients.set(row.session!, 1);
    return { poll: () => undefined, wait: async () => { waited = true; return { code: 0 }; }, release: () => { released = true; } };
  };
  await navigation(row, null);
  assert.ok(waited && released);
});

test("attention colors respect native seen/muted state and fallback uncertainty", () => {
  const cases: [Record<string, unknown>, { status: string } | undefined, string][] = [
    [{ status: "NeedsYou" }, undefined, "1;31"],
    [{ status: "Failed" }, undefined, "1;31"],
    [{ status: "Done" }, undefined, "1;32"],
    [{ status: "Working" }, undefined, "33"],
    [{ status: "Quiet" }, undefined, "36"],
    [{ status: "NewOutput" }, undefined, "36"],
    [{ status: "Idle" }, undefined, "2"],
    [{ status: "Done", seen: true }, undefined, "2"],
    [{ status: "Failed", seen: true }, undefined, "2"],
    [{ status: "NeedsYou", muted: "Pane" }, undefined, "2"],
    [{ status: "Idle" }, { status: "waiting" }, "1;31"],
    [{ status: "Idle", muted: "Pane" }, { status: "waiting" }, "2"],
  ];
  for (const [native, marker, style] of cases) {
    const [rank, status] = attention({ attention: native }, marker);
    const row: Row = { id: "agent", label: "plain", kind: "agent", rank, status,
      display: { prefix: "  └─ ", name: "Pi", detail: "/repo" } };
    const compact = status.replaceAll(" · Zellij", "").replace(/^● /, "! ");
    if (compact === "○ idle") assert.doesNotMatch(renderRow(row), /idle/);
    else assert.ok(renderRow(row).includes(`\x1b[${style}m${compact}\x1b[0m`), status);
    assert.doesNotMatch(renderRow(row), /Zellij/);
    if (marker) assert.match(renderRow(row), /Pi waiting · seen unknown/);
  }
});
test("compact rows retain attention without repeated repo names, paths or repo icons", async () => {
  const path = await repo("repo · with delimiters");
  fake.dirs = [path];
  fake.sessions.set("target", [pane(1, path, { attention: { status: "NeedsYou" }, program_status: [{ app: "pi" }] })]);
  const rows = (await new Catalog().discover()).rows;
  for (const kind of ["repo", "worktree", "agent"]) {
    const row = rows.find((r) => r.kind === kind)!;
    assert.equal(row.rank, 6);
    if (kind !== "repo") assert.match(renderRow(row), /\x1b\[1;31m! needs you\x1b\[0m/);
    assert.ok(!renderRow(row).includes(path));
    if (kind !== "repo") assert.doesNotMatch(renderRow(row), /repo · with delimiters/);
    assert.ok(row.preview!.includes(path));
    assert.match(row.preview!, /Zellij/);
    assert.doesNotMatch(row.label, /\x1b/);
  }
  assert.equal(renderRow(rows.find((r) => r.kind === "repo")!).replace(/\x1b\[[0-9;]*m/g, ""), "repo · with delimiters");
  assert.match(rows.find((r) => r.kind === "worktree")!.preview!, /sessions: target/);
  assert.match(renderRow(rows.find((r) => r.kind === "worktree")!), /⎇ main/);
  assert.match(renderRow(rows.find((r) => r.kind === "agent")!), /◆ shell/);
  fake.sessions.clear();
  const closed = (await new Catalog().discover()).rows.find((r) => r.kind === "worktree")!;
  assert.match(renderRow(closed), /\x1b\[90m⎇ main/);
  assert.doesNotMatch(renderRow(closed), /closed|idle/);
});

test("agent rows show Pane numbers with session identity only in the preview", async () => {
  for (const session of ["session-a", "session-b", "unmapped-agent"]) {
    fake.sessions.set(session, [pane(7, session === "unmapped-agent" ? null : root, { program_status: [{ app: "pi" }] })]);
  }
  const agents = (await new Catalog().discover()).rows.filter((row) => row.kind === "agent");
  assert.equal(agents.length, 3);
  assert.equal(new Set(agents.map((row) => row.id)).size, 3);
  for (const row of agents) {
    assert.match(renderRow(row), /Pane 7/);
    assert.ok(!renderRow(row).includes(row.session!));
    assert.ok(row.preview!.includes(`session: ${row.session}`));
    await selectedPane(row);
  }
});

test("idle, acknowledged and muted live checkouts stay white while closed checkouts are gray", async () => {
  const path = await repo("app"), closed = join(root, "parked");
  await git(path, "worktree", "add", "-b", "parked", closed);
  fake.dirs = [path];
  for (const native of [{ status: "Idle" }, { status: "Done", seen: true }, { status: "NeedsYou", muted: "Pane" }]) {
    fake.sessions.set("live", [pane(1, path, { attention: native })]);
    const catalog = await new Catalog().discover();
    const open = catalog.rows.find((r) => r.kind === "worktree" && r.path === path)!;
    const shut = catalog.rows.find((r) => r.kind === "worktree" && r.path === closed)!;
    assert.equal(open.rank, 0);
    assert.equal(open.open, true);
    assert.equal(shut.open, false);
    assert.match(renderRow(open), /\x1b\[37m⎇ main/);
    assert.match(renderRow(shut), /\x1b\[90m⎇ parked/);
    assert.match(renderRow(catalog.rows.find((r) => r.kind === "repo")!), /\x1b\[1;37mapp/);
    assert.doesNotMatch(renderRow(open), /\[open\]|\[closed\]/);
    assert.match(renderRow(open, false), /\[open\]/);
    assert.match(renderRow(shut, false), /\[closed\]/);
  }
  fake.sessions.clear();
  const catalog = await new Catalog().discover();
  assert.match(renderRow(catalog.rows.find((r) => r.kind === "repo")!), /\x1b\[1;90mapp/);
});

test("uninspectable sessions remain explicitly unavailable rather than claiming closed", async () => {
  fake.sessions.set("unavailable", null);
  fake.sessions.set("live-empty", []);
  const catalog = await new Catalog().discover();
  const unavailable = catalog.rows.find((r) => r.session === "unavailable")!;
  const live = catalog.rows.find((r) => r.session === "live-empty")!;
  assert.equal(unavailable.open, undefined);
  assert.match(renderRow(unavailable), /unavailable/);
  assert.doesNotMatch(renderRow(unavailable), /resurrectable/);
  assert.doesNotMatch(renderRow(unavailable, false), /\[closed\]/);
  assert.match(renderRow(live), /\x1b\[37m▤ live-empty/);
});

test("saved sessions are visibly resurrectable rather than unavailable", async () => {
  fake.sessions.set("saved", null);
  fake.resurrectable.add("saved");
  const row = (await new Catalog().discover()).rows.find((r) => r.session === "saved")!;
  assert.equal(row.open, false);
  assert.match(renderRow(row), /resurrectable/);
  assert.doesNotMatch(renderRow(row), /unavailable/);
  assert.match(row.preview!, /status: resurrectable/);
});

test("rendered metadata cannot inject terminal controls or row delimiters", () => {
  const hostile = "bad\x1b]0;title\x07\n\t\u202e";
  const row: Row = { id: "safe", label: hostile, kind: "repo", status: hostile,
    display: { prefix: hostile, name: hostile, detail: hostile } };
  const rendered = renderRow(row).replace(/\x1b\[[0-9;]*m/g, "");
  assert.doesNotMatch(rendered, /[\x00-\x1f\u202e]/);
  assert.doesNotMatch(renderRow({ id: "confirmation", label: hostile }), /[\x00-\x1f\u202e]/);
  assert.equal(row.id, "safe");
});

test("NO_COLOR keeps icons and state words without fzf or row colors", async () => {
  process.env.NO_COLOR = "1";
  const row: Row = { id: "opaque", label: "plain", kind: "agent", status: "● needs you · Zellij", rank: 6,
    display: { prefix: "", name: "Pi", detail: "/repo" } };
  let input = "";
  mock.method(commands, "capture", async (args: string[], options?: CommandOptions) => {
    input = options?.input ?? "";
    return fake.capture(args, options);
  });
  fake.picks = [["", "opaque"]];
  assert.equal((await choose([row]))[1], row);
  assert.match(input, /◆ Pi  ! needs you/);
  assert.doesNotMatch(input, /\x1b/);
  assert.ok(fake.calls.at(-1)!.includes("--color=bw"));
});

test("dmenu uses unchanged plain labels rather than the fzf display", async () => {
  const row = new Catalog().addRow("repo", "plain repository · Zellij", { path: root, rank: 6,
    display: { prefix: "", name: "decorated repository", detail: root } });
  mock.method(commands, "capture", async (args: string[], options?: CommandOptions) => {
    assert.equal(options?.input, "1. plain repository · Zellij\n");
    return fake.capture(args, options);
  });
  fake.picks = [["", "1. plain"]];
  assert.equal((await choose([row], true))[1], row);
});

test("real fzf searches compact names, activity and PRs without coloring selection IDs", async () => {
  const row = new Catalog().addRow("worktree", "plain label", { path: root, status: "◐ working · Zellij", rank: 1,
    pullRequests: [{ repository: "owner/repo", number: 123, title: "fixture", state: "OPEN", isDraft: false }],
    display: { prefix: "  ├─ ", name: "feature · with spaces", detail: "/repo/context-only" } });
  let input = "";
  mock.method(commands, "capture", async (args: string[], options?: CommandOptions) => {
    input = options?.input ?? "";
    return fake.capture(args, options);
  });
  fake.picks = [["", row.id]];
  assert.equal((await choose([row]))[1], row);
  assert.ok(input.startsWith(`${row.id}\t\x1b[`));
  const args = fake.calls.find((c) => c[0] === "fzf")!;
  assert.ok(args.includes("--ansi"));
  assert.doesNotMatch(input, /context-only/);
  assert.ok(row.preview!.includes(root));
  assert.doesNotMatch(input.split("\t")[2], /\x1b|\[\d+(?:;\d+)*m/);
  for (const query of ["", "feature", "working", "#123"]) {
    const result = await filterInput(input, query);
    assert.equal(result.code, 0, result.stderr);
    assert.equal(result.stdout.trim().split("\t")[0], row.id);
    assert.equal(result.stdout, input, "Filtering must preserve the original ANSI-colored row byte-for-byte");
  }
});

test("real fzf matches visible labels but not opaque selection IDs", async () => {
  const input = "opaque\tAlpha worktree\tAlpha worktree\nsecond\tBeta agent\tBeta agent\n";
  const result = await filterInput(input, "Alpha");
  assert.equal(result.code, 0, result.stderr);
  assert.equal(result.stdout, "opaque\tAlpha worktree\tAlpha worktree\n");
  const absent = await filterInput(input, "opaque");
  assert.equal(absent.code, 0, absent.stderr);
  assert.equal(absent.stdout, "");
});

test("repo searches include children and branch searches include agents in both views", async () => {
  const path = await workspaceWithAgents();
  const linked = join(root, "linked");
  await git(path, "worktree", "add", "-b", "feature/search", linked);
  fake.sessions.set("linked-session", [pane(7, linked, { program_status: [{ app: "pi" }] })]);
  const unrelated = await repo("unrelated");
  fake.sessions.set("unrelated-session", [pane(8, unrelated, { program_status: [{ app: "pi" }] })]);
  const catalog = await new Catalog().discover();
  const rows = catalog.rows.filter((r) => r.kind !== "workspace");
  const agents = catalog.agentRows();
  mock.method(commands, "capture", async (args: string[], options?: CommandOptions) => {
    assert.equal(args[0], "fzf");
    assert.ok(args.includes("--disabled") && args.includes("--with-nth={2}"));
    assert.ok(args.includes("--with-shell=bash --noprofile --norc -c"));
    const action = args.find((arg) => arg.startsWith("change:reload-sync:"))!;
    assert.ok(action.includes("--filter={q}"));
    assert.ok(args.includes(action.replace(/^change:/, "start:")));
    const directory = dirname(args.find((arg) => arg.startsWith("--listen="))!.slice(9));
    for (const view of [rows, agents]) {
      const input = readFileSync(join(directory, "rows"), "utf8");
      const expected = view.filter((r) => r.repo === catalog.locations.get(path)!.repo);
      assert.ok(expected.length < view.length);
      const result = await filterInput(input, "'repo with spaces");
      assert.equal(result.code, 0, result.stderr);
      assert.deepEqual(result.stdout.trim().split("\n").map((line) => line.split("\t")[0]), expected.map((r) => r.id));
      const branch = await filterInput(input, "'repo with spaces feature/search");
      assert.equal(branch.code, 0, branch.stderr);
      assert.deepEqual(branch.stdout.trim().split("\n").map((line) => line.split("\t")[0]), view.filter((r) => r.path === linked).map((r) => r.id));
      const none = await filterInput(input, "'repo with spaces !main !feature/search");
      assert.equal(none.code, 0, none.stderr);
      assert.equal(none.stdout.trim().split("\n").filter(Boolean).length, view === rows ? 1 : 0);
      assert.ok(toggleView(directory).includes(filterCommand(join(directory, "rows"))));
    }
    return { code: 130, stdout: "", stderr: "" };
  });
  await choose(rows, false, undefined, new Promise<void>(() => {}), agents);
});

test("hidden context is sanitized without changing visible labels or row identity", async () => {
  const row: Row = { id: "stable", label: "Pi", search: "repo\tbranch\n\x1b[31mred" };
  mock.method(commands, "capture", async (_args: string[], options?: CommandOptions) => {
    const fields = options!.input!.trimEnd().split("\t");
    assert.deepEqual(fields.slice(0, 2), [row.id, "Pi"]);
    assert.equal(fields.length, 3);
    assert.doesNotMatch(fields[2], /[\n\x1b]/);
    const result = await filterInput(options!.input!, "repo branch");
    assert.equal(result.code, 0, result.stderr);
    return { code: 0, stdout: `\n${result.stdout}`, stderr: "" };
  });
  assert.equal((await choose([row]))[1], row);
});

test("filter ignores inherited UI options and treats queries as data", async () => {
  process.env.FZF_DEFAULT_OPTS = "--disabled --filter=wrong --invalid-option";
  process.env.FZF_DEFAULT_OPTS_FILE = join(root, "missing-options");
  const query = `$(touch ${join(root, "injected")})`;
  const input = `opaque\t${query}\t${query} context\n`;
  const result = await filterInput(input, query);
  assert.equal(result.code, 0, result.stderr);
  assert.equal(result.stdout, input);
  assert.ok(!existsSync(join(root, "injected")));
});

test("filter reports missing row files rather than treating them as no matches", async () => {
  const result = await realCapture(["bash", "--noprofile", "--norc", "-c", filterCommand(join(root, "missing")).replace("{q}", "''")]);
  assert.equal(result.code, 2);
  assert.match(result.stderr, /missing/);
});

test("non-agent failure is not hidden by working agent", async () => {
  fake.sessions.set("mixed", [
    pane(1, root, { program_status: [{ app: "pi" }], attention: { status: "Working", source: "ProgramStatus" } }),
    pane(2, root, { attention: { status: "Failed", seen: false } }),
  ]);
  const catalog = await new Catalog().discover();
  assert.deepEqual(new Set(catalog.targets.map((t) => t.pane)), new Set([1, 2]));
  assert.match(catalog.rows.find((r) => r.kind === "directory")!.status!, /failed/);
});

test("CLI failures are not an empty inventory", async () => {
  mock.method(commands, "capture", async () => ({ code: 1, stdout: "", stderr: "permission denied" }));
  await assert.rejects(sessionNames(), /permission denied/);
  mock.method(commands, "capture", async () => ({ code: 2, stdout: "", stderr: "invalid fzf flag" }));
  await assert.rejects(choose([{ id: "a", label: "one" }]), /invalid fzf flag/);
});

function pr(number: number, headRefName = "main", extra: Record<string, unknown> = {}) {
  return { number, headRefName, title: "Fixture PR", state: "OPEN", isDraft: false, updatedAt: "2026-01-01T00:00:00Z",
    headRepository: { nameWithOwner: "owner/repo" }, ...extra };
}
function connection(nodes: unknown[], hasNextPage = false) { return { nodes, pageInfo: { hasNextPage } }; }
async function githubCatalog() {
  const path = await repo();
  await git(path, "remote", "add", "origin", "git@github.com:owner/repo.git");
  fake.dirs = [path];
  return { path, catalog: await new Catalog().discover() };
}

test("GitHub remotes are parsed without accepting other hosts, credentials or unsafe paths", () => {
  for (const url of ["https://github.com/Owner/Repo.git", "git@github.com:Owner/Repo.git", "ssh://git@github.com/Owner/Repo",
    "https://github.com/Owner/Repo/", "ssh://git@github.com:22/Owner/Repo.git"]) assert.equal(githubRepository(url), "Owner/Repo");
  for (const url of ["https://gitlab.com/a/b", "https://github.com.evil/a/b", "https://token@github.com/a/b", "/local/repo",
    "https://github.com/a/..", "https://github.com/a/b?secret=x", "https://github.com/a/b\n"]) assert.equal(githubRepository(url), null);
});

test("PR lookup batches worktrees and fork parents, matching both repository and remote branch", async () => {
  const { path } = await githubCatalog(), tree = join(root, "feature");
  await git(path, "worktree", "add", "-b", "local-name", tree);
  await git(path, "config", "branch.local-name.remote", "origin");
  await git(path, "config", "branch.local-name.merge", "refs/heads/remote-name");
  const catalog = await new Catalog().discover(), identities = catalog.rows.map((r) => r.id);
  fake.githubResponses = [{ data: { repository: { nameWithOwner: "owner/repo", b0: connection([]), b1: connection([]),
    parent: { nameWithOwner: "upstream/repo", b0: connection([pr(9, "main", { headRepository: { nameWithOwner: "other/repo" } })]),
      b1: connection([pr(42, "remote-name", { title: "Safe\x1b]0;bad\x07\nTitle", isDraft: true })]) } } } }];
  await catalog.loadGithub();
  assert.deepEqual(catalog.rows.map((r) => r.id), identities);
  assert.equal(fake.calls.filter((c) => c[0] === "gh").length, 1);
  const row = catalog.rows.find((r) => r.path === tree)!;
  assert.equal(row.pullRequests![0].repository, "upstream/repo");
  assert.match(renderRow(row), / #42/);
  assert.match(renderRow(row, false), /^  ├─  #42 local-name/);
  assert.match(row.preview!, /https:\/\/github.com\/upstream\/repo\/pull\/42/);
  assert.doesNotMatch(row.preview!, /[\x1b\x07]/);
  assert.deepEqual(catalog.rows.find((r) => r.kind === "worktree" && r.branch === "main")!.pullRequests, []);
  assert.deepEqual(fake.mutations(), []);
});

test("all matching open PRs win over closed history and badge colors preserve lifecycle", async () => {
  const { catalog } = await githubCatalog();
  fake.githubResponses = [{ data: { repository: { nameWithOwner: "owner/repo", b0: connection([
    pr(8, "main", { state: "CLOSED", updatedAt: "2026-02-01T00:00:00Z" }), pr(7), pr(6, "main", { isDraft: true }),
  ]), parent: null } } }];
  await catalog.loadGithub();
  const row = catalog.rows.find((r) => r.kind === "worktree")!;
  assert.deepEqual(row.pullRequests!.map((pr) => pr.number), [7, 6]);
  assert.match(renderRow(row), /\x1b\[32m #7 /);
  assert.match(renderRow(row), /\x1b\[2m #6 /);
  assert.match(renderRow(row, false), /^  ├─  #7  #6 main/);
  for (const [state, color, glyph] of [["MERGED", "35", ""], ["CLOSED", "31", ""]]) {
    row.pullRequests = [{ repository: "owner/repo", number: 1, title: "fixture", state, isDraft: false }];
    assert.ok(renderRow(row).includes(`\x1b[${color}m${glyph} #1 `));
    assert.doesNotMatch(renderRow(row, false), /\x1b/);
  }
});

test("latest merged PR is selected across the fork and parent when none remain open", async () => {
  const { catalog } = await githubCatalog();
  fake.githubResponses = [{ data: { repository: { nameWithOwner: "owner/repo", b0: connection([pr(2, "main", { state: "CLOSED" })]),
    parent: { nameWithOwner: "upstream/repo", b0: connection([pr(3, "main", { state: "MERGED", updatedAt: "2026-03-01T00:00:00Z" })]) } } } }];
  await catalog.loadGithub();
  assert.equal(catalog.rows.find((r) => r.kind === "worktree")!.pullRequests![0].number, 3);
});

test("failed, malformed and truncated GitHub responses do not imply no PR", async () => {
  const { path } = await githubCatalog();
  for (const response of [null, {}, { errors: [{ message: "rate limited" }] },
    { data: { repository: { nameWithOwner: "owner/repo", b0: connection([pr(1)], true) } } }]) {
    const catalog = await new Catalog().discover();
    fake.githubResponses = [response];
    await catalog.loadGithub();
    const row = catalog.rows.find((r) => r.kind === "worktree")!;
    assert.deepEqual(row.pullRequests, []);
    assert.match(row.preview!, /unavailable or incomplete/);
    assert.equal(row.path, path);
    assert.deepEqual(fake.mutations(), []);
  }
});

test("push remote takes precedence and detached/non-GitHub checkouts do not query GitHub", async () => {
  const { path } = await githubCatalog();
  await git(path, "remote", "add", "upstream", "https://github.com/upstream/repo.git");
  await git(path, "config", "branch.main.remote", "upstream");
  await git(path, "config", "branch.main.pushRemote", "origin");
  await git(path, "config", "remote.origin.pushurl", "fixture:owner/repo.git");
  await git(path, "config", "url.https://github.com/.insteadOf", "fixture:");
  fake.githubResponses = [{ data: { repository: { nameWithOwner: "owner/repo", b0: connection([]) } } }];
  await (await new Catalog().discover()).loadGithub();
  assert.ok(fake.calls.find((c) => c[0] === "gh")!.at(-1)!.includes('owner:"owner"'));
  const before = fake.calls.filter((c) => c[0] === "gh").length;
  await git(path, "config", "--unset", "remote.origin.pushurl");
  await git(path, "remote", "set-url", "origin", "https://gitlab.com/owner/repo.git");
  await (await new Catalog().discover()).loadGithub();
  await git(path, "checkout", "--detach");
  await (await new Catalog().discover()).loadGithub();
  assert.equal(fake.calls.filter((c) => c[0] === "gh").length, before);
});

test("preview reports ahead/behind from local refs without fetching and detects checkout changes", async () => {
  const path = await repo();
  assert.match(await gitPreview(path, "main"), /no available upstream/);
  await git(path, "branch", "upstream");
  await git(path, "branch", "--set-upstream-to=upstream", "main");
  assert.match(await gitPreview(path, "main"), /↑ 0 ahead · ↓ 0 behind/);
  await git(path, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-m", "ahead");
  assert.match(await gitPreview(path, "main"), /↑ 1 ahead · ↓ 0 behind/);
  await git(path, "checkout", "upstream");
  await git(path, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-m", "behind");
  await git(path, "checkout", "main");
  assert.match(await gitPreview(path, "main"), /↑ 1 ahead · ↓ 1 behind/);
  assert.match(await gitPreview(path, "old-name"), /checkout changed/);
  assert.ok(!fake.calls.some((c) => c.includes("fetch")));
});

test("CI preview distinguishes passing, failed, pending, absent and unavailable checks", async () => {
  const pull = { repository: "owner/repo", number: 42, title: "test", state: "OPEN", isDraft: false };
  for (const [state, expected] of [["SUCCESS", "✓ passing"], ["FAILURE", "✗ failed"], ["ERROR", "✗ failed"],
    ["PENDING", "◐ pending"], ["EXPECTED", "◐ pending"], ["OTHER", "? unknown"], [null, "no checks reported"]]) {
    fake.githubResponses = [{ data: { r0: { pullRequest: { commits: { nodes: [{ commit: { statusCheckRollup: state ? { state } : null } }] } } } } }];
    assert.ok((await pullRequestPreview([pull])).includes(expected!));
  }
  fake.githubResponses = [null];
  assert.match(await pullRequestPreview([pull]), /unavailable/);
  assert.equal(await pullRequestPreview([]), "");
});

test("fzf snapshot lazily loads Git and CI without Zellij actions or command-line metadata", async () => {
  const path = await repo(), catalog = new Catalog();
  const row = catalog.addRow("worktree", "test", { path, branch: "main", pullRequests: [
    { repository: "owner/repo", number: 42, title: "fixture", state: "OPEN", isDraft: false },
  ] });
  const output = mock.method(console, "log", () => {});
  mock.method(commands, "capture", async (args: string[], options?: CommandOptions) => {
    if (args[0] === "fzf") {
      const command = args[args.indexOf("--preview") + 1];
      const snapshot = /'--preview' '([^']+)'/.exec(command)![1];
      assert.equal(JSON.parse(readFileSync(snapshot, "utf8"))[row.id].identity, undefined);
      await main(["--preview", snapshot, row.id]);
    }
    return fake.capture(args, options);
  });
  fake.githubResponses = [{ data: { r0: { pullRequest: { commits: { nodes: [{ commit: { statusCheckRollup: { state: "SUCCESS" } } }] } } } } }];
  fake.picks = [["", row.id]];
  assert.equal((await choose([row]))[1], row);
  assert.ok(output.mock.calls.some((c) => String(c.arguments[0]).includes("CI #42: ✓ passing")));
  assert.equal(fake.calls.filter((c) => c[0] === "gh").length, 1);
  assert.ok(!fake.calls.some((c) => c[0] === "zellij"));
});

test("live PR updates atomically refresh only the active view with stable IDs", { timeout: 5000 }, async () => {
  process.env.FZF_API_KEY = "fixture-key";
  const row: Row = { id: "stable", label: "main", kind: "worktree", path: root, branch: "main", open: true,
    preview: "original", display: { prefix: "", name: "main", detail: root } };
  let finish!: () => void;
  const metadata = new Promise<void>((resolve) => { finish = resolve; });
  let received!: (body: string) => void;
  const posted = new Promise<string>((resolve) => { received = resolve; });
  let apiKey: string | string[] | undefined;
  const server = createServer((req, res) => {
    apiKey = req.headers["x-api-key"];
    let body = "";
    req.on("data", (chunk) => { body += chunk; });
    req.on("end", () => { res.end("ok"); received(body); });
  });
  const directories: string[] = [];
  mock.method(commands, "capture", async (args: string[], options?: CommandOptions) => {
    assert.equal(args[0], "fzf");
    assert.ok(args.includes("--track") && args.includes("--id-nth=1"));
    const socket = args.find((arg) => arg.startsWith("--listen="))!.slice("--listen=".length);
    const directory = dirname(socket);
    directories.push(directory);
    assert.equal(statSync(directory).mode & 0o777, 0o700);
    assert.doesNotMatch(options!.input!, /#42/);
    if (directories.length === 1) return { code: 130, stdout: "", stderr: "" };
    await new Promise<void>((resolve) => server.listen(socket, resolve));
    toggleView(directory);
    row.pullRequests = [{ repository: "owner/repo", number: 42, title: "ready", state: "OPEN", isDraft: false }];
    row.preview = "PR title and URL ready";
    finish();
    const action = await posted;
    assert.equal(apiKey, "fixture-key");
    assert.equal(action, `refresh-preview+reload-sync:${filterCommand(join(directory, "rows"))}`);
    assert.ok(action.includes(directory));
    assert.ok(!existsSync(directories[0]));
    const snapshot = JSON.parse(readFileSync(join(directory, "preview.json"), "utf8"));
    assert.equal(snapshot.stable.text, row.preview);
    assert.equal(snapshot.stable.pullRequests[0].number, 42);
    assert.equal(snapshot.stable.identity, undefined);
    assert.equal(readlinkSync(join(directory, "rows")), "agents");
    assert.equal(readFileSync(join(directory, "rows"), "utf8"), "");
    toggleView(directory);
    const input = readFileSync(join(directory, "rows"), "utf8");
    assert.match(input, /^stable\t/);
    assert.match(input, / #42/);
    assert.ok(!readdirSync(directory).some((name) => name.endsWith(".tmp")));
    return { code: 0, stdout: "\n" + input, stderr: "" };
  });
  try {
    assert.equal((await choose([row], false, undefined, metadata, []))[0], "cancel");
    assert.equal((await choose([row], false, undefined, metadata, []))[1], row);
    assert.ok(directories.every((directory) => !existsSync(directory)));
  } finally { server.closeAllConnections(); await new Promise<void>((resolve) => server.close(() => resolve())); }
});

test("closing a picker does not wait for metadata or recreate its files on late completion", async () => {
  let finish!: () => void, directory = "";
  const metadata = new Promise<void>((resolve) => { finish = resolve; });
  const warnings = mock.method(console, "error", () => {});
  mock.method(commands, "capture", async (args: string[]) => {
    directory = dirname(args.find((arg) => arg.startsWith("--listen="))!.slice("--listen=".length));
    return { code: 130, stdout: "", stderr: "" };
  });
  assert.equal((await choose([{ id: "one", label: "one" }], false, undefined, metadata))[0], "cancel");
  assert.ok(!existsSync(directory));
  finish();
  await metadata;
  await sleep(0);
  assert.ok(!existsSync(directory));
  assert.equal(warnings.mock.calls.length, 0);
});

for (const cancel of [false, true]) {
  test(`${cancel ? "cancellation" : "navigation"} proceeds before GitHub completes and aborts its request`, { timeout: 5000 }, async () => {
    const { path } = await githubCatalog();
    await source();
    fake.sessions.get("source")!.push(pane(2, path));
    let opened = false, cancelled = false, started!: () => void;
    const querying = new Promise<void>((resolve) => { started = resolve; });
    mock.method(commands, "capture", async (args: string[], options?: CommandOptions) => {
      if (args[0] === "fzf") { opened = true; await querying; }
      if (args[0] === "gh") {
        assert.equal(opened, true);
        assert.ok(options?.signal && !options.signal.aborted);
        return new Promise<CommandResult>((resolve) => {
          options.signal!.addEventListener("abort", () => {
            cancelled = true;
            resolve({ code: 1, stdout: "", stderr: "cancelled fixture request" });
          }, { once: true });
          started();
        });
      }
      return fake.capture(args, options);
    });
    fake.picks = cancel ? [null] : [["", "⎇ main"]];
    await main([]);
    assert.equal(cancelled, true);
    if (cancel) assert.ok(fake.mutations().every((args) => args.includes("hide-floating-panes")));
    else assert.equal(fake.mutations().at(-1)!.at(-1), "terminal_2");
  });
}

test("Ctrl-R cancels the old enrichment before starting another catalog", async () => {
  await workspaceWithAgents();
  const signals: AbortSignal[] = [];
  mock.method(Catalog.prototype, "loadGithub", async (signal: AbortSignal) => {
    assert.ok(signals.every((previous) => previous.aborted));
    signals.push(signal);
    await new Promise<void>((resolve) => signal.addEventListener("abort", () => resolve(), { once: true }));
  });
  fake.picks = [["ctrl-r", "⎇ main"], null];
  await main([]);
  assert.equal(signals.length, 2);
  assert.ok(signals.every((signal) => signal.aborted));
});

test("subprocess cancellation settles without waiting for the command timeout", async () => {
  const controller = new AbortController();
  const pending = realCapture([process.execPath, "-e", "setInterval(() => {}, 1000)"], { signal: controller.signal, timeout: 10000 });
  controller.abort();
  const result = await pending;
  assert.equal((result.error as NodeJS.ErrnoException)?.code, "ABORT_ERR");
});

test("plain list remains offline and GitHub failure does not prevent exact navigation", async () => {
  const { path } = await githubCatalog();
  mock.method(console, "log", () => {});
  await main(["--list"]);
  assert.ok(!fake.calls.some((c) => c[0] === "gh"));
  await source();
  fake.sessions.get("source")!.push(pane(2, path));
  fake.githubResponses = [null];
  let failed!: () => void;
  const failure = new Promise<void>((resolve) => { failed = resolve; });
  mock.method(commands, "capture", async (args: string[], options?: CommandOptions) => {
    if (args[0] === "fzf") await failure;
    const result = await fake.capture(args, options);
    if (args[0] === "gh") failed();
    return result;
  });
  fake.picks = [["", "⎇ main"]];
  await main([]);
  assert.ok(fake.calls.some((args) => args[0] === "gh"));
  assert.equal(fake.mutations().at(-1)!.at(-1), "terminal_2");
});

test("path and row hashes match the Python version, including Unicode", () => {
  assert.equal(key("repo", "/tmp/a b", null, null), "86befa92d870af3b");
  assert.equal(key("agent", "/tmp/é/🦊", "name", 2), "8c6295d55ad98e57");
  assert.equal(key("/tmp/space repo"), "994590bfda5a19ad");
  assert.equal(key("/tmp/仓库"), "10982b14bd14885d");
});

test("symlinked checkout has the same session identity", async () => {
  const path = await repo();
  const alias = join(root, "alias");
  symlinkSync(path, alias);
  const catalog = new Catalog();
  assert.equal(await catalog.locate(alias), path);
  assert.equal(await newSessionName(path), await newSessionName(alias));
});

test("terminal spawn failures are reported and released", async () => {
  const row = target();
  let released = false;
  fake.launchHandler = () => ({ poll: () => ({ code: null, error: new Error("missing terminal") }),
    wait: async () => ({ code: null }), release: () => { released = true; } });
  await assert.rejects(navigation(row, null), /Terminal exited/);
  assert.ok(released);
});

test("dmenu child is released without waiting for its window to close", async () => {
  const row = target();
  let released = false;
  fake.launchHandler = (args, options) => {
    assert.equal(args[0], "footclient");
    assert.equal(options.detached, true);
    fake.clients.set(row.session!, 1);
    return { poll: () => undefined, wait: async () => { assert.fail("must not wait for desktop window exit"); },
      release: () => { released = true; } };
  };
  await navigation(row, null, true);
  assert.ok(released);
});

test("missing executable is a command failure, not a stdin exception", async () => {
  const result = await realCapture([join(root, "missing-executable")]);
  assert.equal(result.code, null);
  assert.match(result.error!.message, /ENOENT/);
});

test("Ctrl-C forwards to fzf and cleans up only the fixture picker", { timeout: 10000 }, async () => {
  const bin = join(root, "bin"), ready = join(root, "ready"), hidden = join(root, "hidden");
  mkdirSync(bin);
  const executable = (name: string, text: string) => writeFileSync(join(bin, name), `#!${process.execPath}\n${text}`, { mode: 0o755 });
  const entries = [pane(9, root, { is_floating: true, title: "zs" }), pane(1, root)];
  executable("zellij", `
    const fs = require('node:fs'), args = process.argv.slice(2);
    if (args.includes('list-sessions')) console.log('source');
    else if (args.includes('list-panes')) console.log(${JSON.stringify(JSON.stringify(entries))});
    else if (args.includes('list-clients')) console.log('CLIENT_ID ZELLIJ_PANE_ID\\n0 terminal_9');
    else if (args.includes('hide-floating-panes')) fs.writeFileSync(${JSON.stringify(hidden)}, args.at(-1));
    else process.exit(99);
  `);
  executable("zoxide", "process.exit(0);");
  executable("fzf", `require('node:fs').writeFileSync(${JSON.stringify(ready)}, 'ready'); setInterval(() => {}, 1000);`);
  const child = spawn(process.execPath, ["--experimental-strip-types", fileURLToPath(new URL("main.ts", import.meta.url))], {
    cwd: root, env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, ZELLIJ_SESSION_NAME: "source", ZELLIJ_PANE_ID: "9" },
    stdio: ["ignore", "pipe", "pipe"], detached: true,
  });
  let stderr = "";
  child.stderr!.on("data", (chunk) => { stderr += chunk; });
  const exit = new Promise<number | null>((done, reject) => {
    child.once("error", reject);
    child.once("exit", done);
  });
  try {
    const deadline = performance.now() + 5000;
    while (!existsSync(ready) && performance.now() < deadline && child.exitCode === null) await sleep(20);
    assert.ok(existsSync(ready), stderr);
    child.kill("SIGINT");
    assert.equal(await exit, 130, stderr);
    assert.equal(readFileSync(hidden, "utf8"), "10");
  } finally {
    // This process group contains only the disposable fixture CLI and its fake commands.
    if (child.pid) {
      try { process.kill(-child.pid, "SIGKILL"); }
      catch (error) { if ((error as NodeJS.ErrnoException).code !== "ESRCH") throw error; }
    }
  }
});
