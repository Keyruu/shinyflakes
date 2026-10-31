import { commands, run, PickerError } from "./commands.ts";
import type { CommandOptions } from "./commands.ts";
import { clean, object, json, compare } from "./text.ts";
import { githubRepository, loadGithub, pullRequestPreview } from "./github.ts";
import type { GithubMetadata, PullRequest } from "./github.ts";
import { attention, dmenuLabel, renderRow, rowLabel, rowPreview } from "./presentation.ts";
import type { Attention } from "./presentation.ts";
import { createHash } from "node:crypto";
import {
  closeSync,
  constants,
  futimesSync,
  lstatSync,
  mkdirSync,
  mkdtempSync,
  openSync,
  readFileSync,
  readdirSync,
  readlinkSync,
  realpathSync,
  renameSync,
  rmSync,
  statSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { homedir, tmpdir } from "node:os";
import { request } from "node:http";
import { basename, dirname, isAbsolute, join, resolve, sep } from "node:path";
import { setTimeout as sleep } from "node:timers/promises";
import { fileURLToPath, pathToFileURL } from "node:url";
import {
  isDeepStrictEqual,
  parseArgs,
  stripVTControlCharacters,
} from "node:util";

let interrupted = false;
function checkInterrupt(): void {
  if (interrupted) throw new PickerError("Interrupted");
}

export function key(...parts: (string | number | null | undefined)[]): string {
  // Preserve Python's original JSON encoding so row IDs and visit-cache keys stay stable.
  const encoded = `[${parts
    .map((p) =>
      JSON.stringify(p ?? null).replace(
        /[\u007f-\uffff]/g,
        (c) => `\\u${c.charCodeAt(0).toString(16).padStart(4, "0")}`,
      ),
    )
    .join(", ")}]`;
  return createHash("sha256").update(encoded).digest("hex").slice(0, 16);
}

export function canonical(path: string): string {
  const absolute = resolve(
    path === "~"
      ? homedir()
      : path.startsWith("~/")
        ? join(homedir(), path.slice(2))
        : path,
  );
  try {
    return realpathSync(absolute);
  } catch (error) {
    if (
      !["ENOENT", "ENOTDIR"].includes(
        (error as NodeJS.ErrnoException).code ?? "",
      )
    )
      throw error;
    return dirname(absolute) === absolute
      ? absolute
      : join(canonical(dirname(absolute)), basename(absolute));
  }
}
function isDirectory(path: unknown): path is string {
  if (typeof path !== "string" || !isAbsolute(path)) return false;
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}
function lines(text: string): string[] {
  return text.replace(/\n$/, "").split("\n");
}
async function action(
  session: string,
  args: string[],
  options?: CommandOptions,
): Promise<string | null> {
  return run(["zellij", `--session=${session}`, "action", ...args], options);
}

export interface Pane {
  id: number;
  tab_id: number;
  is_plugin: boolean;
  tab_name?: string;
  title?: string;
  exited?: boolean;
  terminal_command?: string | null;
  pane_cwd?: string | null;
  is_selectable?: boolean;
  is_floating?: boolean;
  is_focused?: boolean;
  attention?: Record<string, unknown>;
  program_status?: Record<string, unknown>[];
}
export interface Marker {
  pid: number;
  stamp: string;
  zellijSession: string;
  zellijPaneId?: string | number;
  taskRoot?: string;
  cwd?: string;
  status?: string;
  sessionId?: string | null;
  sessionFile?: string | null;
}
export type MarkerIdentity = Pick<
  Marker,
  "pid" | "stamp" | "sessionId" | "sessionFile"
>;
export type PaneIdentity = ReturnType<typeof paneIdentity>;
export interface Target {
  kind: "agent" | "workspace";
  session: string;
  pane: number;
  tab: number;
  path: string | null;
  identity: PaneIdentity;
  rank: number;
  activity: Attention;
  title: string;
  marker?: MarkerIdentity;
}
export interface Location {
  path: string;
  repo: string | null;
  branch: string;
  worktree?: string[];
}
export interface Repo {
  path: string;
  trees: string[];
  name: string;
  main?: string;
}
export interface Choice {
  id: string;
  label: string;
  preview?: string;
}
export interface Row {
  id: string;
  label?: string;
  preview?: string;
  kind?: "repo" | "worktree" | "directory" | "session" | Target["kind"];
  path?: string | null;
  repo?: string | null;
  branch?: string;
  session?: string;
  savedSession?: string;
  tab?: number;
  pane?: number;
  status?: string;
  activity?: Attention;
  sessions?: string[];
  github?: GithubMetadata;
  rank?: number;
  open?: boolean;
  identity?: PaneIdentity;
  marker?: MarkerIdentity;
  title?: string;
  display?: { prefix: string; name: string; detail: string; context?: string };
  pullRequests?: PullRequest[];
  worktree?: string[];
  search?: string;
}
export interface Source {
  session: string;
  pane: number;
  identity: PaneIdentity;
  tab: number;
  floating: boolean;
  hidden?: boolean;
}

function visitDirectory(): string {
  return join(
    process.env.XDG_CACHE_HOME ?? join(homedir(), ".cache"),
    "zs",
    "visits",
  );
}
function visitKey(row: Row): string | null {
  if (
    (row.kind === "agent" || row.kind === "workspace") &&
    row.session &&
    row.pane !== undefined
  )
    return key("pane", row.session, row.pane);
  if (row.kind === "session" && row.session) return key("session", row.session);
  return row.kind !== "repo" && row.path
    ? key("checkout", canonical(row.path))
    : null;
}
export function lastVisit(row: Row): number {
  try {
    const id = visitKey(row);
    if (!id) return 0;
    const stat = lstatSync(join(visitDirectory(), id));
    const time = stat.mtime.getTime();
    return stat.isFile() && time > 0 && time <= Date.now() ? time : 0;
  } catch {
    return 0;
  }
}
export function recordVisit(row: Row): void {
  try {
    const ids = [
      row.path ? key("checkout", canonical(row.path)) : null,
      row.session ? key("session", row.session) : null,
      row.session && row.pane !== undefined
        ? key("pane", row.session, row.pane)
        : null,
    ].filter((id) => id !== null);
    if (!ids.length) return;
    mkdirSync(visitDirectory(), { recursive: true, mode: 0o700 });
    // Independent timestamp files avoid lost updates between pickers; no task, title or seen state is stored.
    for (const id of ids) {
      const fd = openSync(
        join(visitDirectory(), id),
        constants.O_CREAT | constants.O_WRONLY | constants.O_NOFOLLOW,
        0o600,
      );
      try {
        const now = new Date(Date.now());
        futimesSync(fd, now, now);
      } finally {
        closeSync(fd);
      }
    }
  } catch (error) {
    console.error(
      `zs: navigation succeeded, but visit history could not be saved: ${clean(error instanceof Error ? error.message : error)}`,
    );
  }
}

export function orderRows(rows: Row[]): Row[] {
  type Group = {
    row: Row;
    children: Group[];
    priority: number;
    visited: number;
  };
  const groups: Group[] = rows.map((row) => ({
    row,
    children: [],
    priority: (row.rank ?? 0) >= 5 ? 2 : row.rank === 4 ? 1 : 0,
    visited: lastVisit(row),
  }));
  const repos = new Map(
    groups.filter((g) => g.row.kind === "repo").map((g) => [g.row.repo, g]),
  );
  const locations = new Map(
    groups
      .filter((g) => g.row.kind === "worktree" || g.row.kind === "directory")
      .map((g) => [g.row.path, g]),
  );
  const sessions = new Map(
    groups
      .filter((g) => g.row.kind === "session")
      .map((g) => [g.row.session, g]),
  );
  const roots: Group[] = [];
  for (const group of groups) {
    const row = group.row;
    const parent =
      row.kind === "worktree"
        ? repos.get(row.repo)
        : row.kind === "agent" || row.kind === "workspace"
          ? (locations.get(row.path) ?? sessions.get(row.session))
          : undefined;
    (parent ? parent.children : roots).push(group);
  }
  const sort = (siblings: Group[]) => {
    for (const group of siblings) {
      sort(group.children);
      for (const child of group.children) {
        group.priority = Math.max(group.priority, child.priority);
        group.visited = Math.max(group.visited, child.visited);
      }
    }
    // Stable ties preserve the existing deterministic order before any visits are recorded.
    siblings.sort((a, b) => b.priority - a.priority || b.visited - a.visited);
  };
  sort(roots);
  const flatten = (siblings: Group[]): Row[] =>
    siblings.flatMap((g) => [g.row, ...flatten(g.children)]);
  return flatten(roots);
}

export async function sessionNames(): Promise<string[]> {
  try {
    return [
      ...new Set(
        lines(
          (await run([
            "zellij",
            "list-sessions",
            "--no-formatting",
            "--short",
          ]))!,
        ).filter(Boolean),
      ),
    ];
  } catch (error) {
    if (
      error instanceof PickerError &&
      error.message === "No active zellij sessions found."
    )
      return [];
    throw error;
  }
}
export async function resurrectableSessions(): Promise<Set<string>> {
  const output = await run(["zellij", "list-sessions", "--no-formatting"], {
    optional: true,
  });
  return new Set(
    lines(output ?? "").flatMap((line) => {
      const match =
        /^(.+) \[Created [^\]\r\n]+ ago\] \(EXITED - attach to resurrect\)$/.exec(
          line,
        );
      return match ? [match[1]] : [];
    }),
  );
}
export async function panes(session: string): Promise<Pane[] | null> {
  // Failure alone cannot distinguish a saved session from an unreachable live server.
  const value = json(
    await action(session, ["list-panes", "--json", "--all"], {
      optional: true,
    }),
  );
  if (
    !Array.isArray(value) ||
    value.some(
      (p) =>
        !object(p) ||
        !Number.isInteger(p.id) ||
        !Number.isInteger(p.tab_id) ||
        typeof p.is_plugin !== "boolean",
    )
  )
    return null;
  return value as Pane[];
}
export async function clients(session: string): Promise<string[]> {
  const output = lines((await action(session, ["list-clients"]))!);
  if (output[0]?.trim().split(/\s+/)[0] !== "CLIENT_ID")
    throw new PickerError(`Cannot validate clients for ${clean(session)}`);
  return output
    .slice(1)
    .filter((line) => line.trim())
    .map((line) => {
      const id = line.trim().split(/\s+/)[0];
      if (!/^\d+$/.test(id))
        throw new PickerError(
          "Unrecognized client listing; refusing navigation",
        );
      return id;
    });
}
export function processStamp(pid: number): string | null {
  try {
    const text = readFileSync(`/proc/${pid}/stat`, "utf8");
    const fields = text.slice(text.lastIndexOf(") ") + 2).split(" ");
    return fields[0] !== "Z" && /^\d+$/.test(fields[19]) ? fields[19] : null;
  } catch {
    return null;
  }
}
export async function agentMarkers(): Promise<Marker[]> {
  const directory = join(
    process.env.XDG_CACHE_HOME ?? join(homedir(), ".cache"),
    "pi-herd",
  );
  let entries: string[];
  try {
    entries = readdirSync(directory).filter((name) => /^\d+\.json$/.test(name));
  } catch {
    return [];
  }
  if (!entries.length) return [];
  const ticks = Number(await run(["getconf", "CLK_TCK"]));
  if (!Number.isFinite(ticks) || ticks <= 0)
    throw new PickerError("Cannot determine process start clock ticks");
  const result: Marker[] = [];
  for (const entry of entries) {
    try {
      const file = join(directory, entry);
      const marker = json(readFileSync(file, "utf8"));
      const pid = Number(entry.slice(0, -5)),
        stamp = processStamp(pid);
      if (
        !object(marker) ||
        marker.pid !== pid ||
        !stamp ||
        typeof marker.zellijSession !== "string"
      )
        continue;
      // A recycled PID must not bring an old marker back to life.
      const uptime = Number(readFileSync("/proc/uptime", "utf8").split(" ")[0]);
      const started = Date.now() / 1000 - uptime + Number(stamp) / ticks;
      if (statSync(file).mtimeMs / 1000 + 1 < started) continue;
      result.push({ ...marker, stamp } as Marker);
    } catch {
      /* A publisher may replace or remove its marker during discovery. */
    }
  }
  return result;
}

export function taskRoot(pane: Pane): string | null {
  // RunCommand::fmt joins argv without quoting; only decode pi-task's adjacent bindings.
  return (
    /^(?:\S*\/)?env PI_TASK_ROOT=(\/.*?) PI_TASK_REVIEW_STATE=\//s.exec(
      pane.terminal_command ?? "",
    )?.[1] ?? null
  );
}
export function paneIdentity(pane: Pane) {
  return {
    id: pane.id,
    is_plugin: pane.is_plugin,
    tab_id: pane.tab_id,
    terminal_command: pane.terminal_command ?? null,
    pane_cwd: pane.pane_cwd ?? null,
    exited: pane.exited ?? null,
  };
}

export async function gitPreview(
  path: string,
  branch: string,
): Promise<string> {
  const current = (
    await run(
      ["git", "-C", path, "symbolic-ref", "--quiet", "--short", "HEAD"],
      { optional: true },
    )
  )?.trim();
  if (current !== branch)
    return "Git: checkout changed or detached; refresh the picker";
  const upstream = (
    await run(["git", "-C", path, "rev-parse", "--abbrev-ref", "@{upstream}"], {
      optional: true,
    })
  )?.trim();
  if (!upstream) return "Git: no available upstream tracking ref";
  const counts = await run(
    [
      "git",
      "-C",
      path,
      "rev-list",
      "--left-right",
      "--count",
      "HEAD...@{upstream}",
    ],
    { optional: true },
  );
  const match = /^(\d+)\s+(\d+)\s*$/.exec(counts ?? "");
  return match
    ? `Git: ↑ ${match[1]} ahead · ↓ ${match[2]} behind ${clean(upstream)} (local refs; no fetch)`
    : "Git: tracking counts unavailable";
}
export class Catalog {
  sessions = new Map<string, Pane[] | null>();
  resurrectable = new Set<string>();
  repos = new Map<string, Repo>();
  locations = new Map<string, Location>();
  targets: Target[] = [];
  paneTargets: Target[] = [];
  rows: Row[] = [];
  gitCache = new Map<string, string | null>();

  async locate(path: unknown): Promise<string | null> {
    if (!isDirectory(path)) return null;
    const directory = canonical(path);
    if (this.gitCache.has(directory)) return this.gitCache.get(directory)!;
    const output = await run(
      [
        "git",
        "-C",
        directory,
        "rev-parse",
        "--path-format=absolute",
        "--git-common-dir",
      ],
      { optional: true },
    );
    if (!output) {
      this.gitCache.set(directory, null);
      return null;
    }
    const common = canonical(output.replace(/\n$/, ""));
    if (!this.repos.has(common)) {
      const listing = await run(
        ["git", "-C", directory, "worktree", "list", "--porcelain", "-z"],
        { optional: true },
      );
      if (listing === null) {
        this.gitCache.set(directory, null);
        return null;
      }
      const trees: string[] = [];
      let main: string | undefined, name: string | undefined;
      for (const [index, block] of listing.split("\0\0").entries()) {
        const fields = block.split("\0");
        const values = new Map(
          fields
            .filter((f) => f.includes(" "))
            .map((f) => [
              f.slice(0, f.indexOf(" ")),
              f.slice(f.indexOf(" ") + 1),
            ]),
        );
        if (!values.get("worktree")) continue;
        const root = canonical(values.get("worktree")!);
        if (index === 0) {
          name = basename(root);
          if (fields.includes("bare")) name = name.replace(/\.git$/, "");
          else main = root;
        }
        if (fields.includes("bare")) continue;
        const branch = values.get("branch")?.replace(/^refs\/heads\//, "");
        trees.push(root);
        this.locations.set(root, {
          path: root,
          repo: common,
          branch:
            branch || `detached ${(values.get("HEAD") ?? "").slice(0, 8)}`,
          worktree: fields,
        });
      }
      if (!trees.length) {
        this.gitCache.set(directory, null);
        return null;
      }
      this.repos.set(common, {
        path: trees[0],
        trees,
        name: name || basename(trees[0]),
        main,
      });
    }
    const location =
      this.repos
        .get(common)!
        .trees.filter(
          (root) => directory === root || directory.startsWith(root + sep),
        )
        .sort((a, b) => b.length - a.length)[0] ?? null;
    this.gitCache.set(directory, location);
    return location;
  }

  async discover(): Promise<this> {
    const names = await sessionNames();
    // Limit outstanding server queries; one stalled session must not serialize discovery.
    for (let i = 0; i < names.length; i += 4) {
      for (const [name, entries] of await Promise.all(
        names
          .slice(i, i + 4)
          .map(async (name) => [name, await panes(name)] as const),
      )) {
        this.sessions.set(name, entries);
      }
    }
    if ([...this.sessions.values()].some((entries) => entries === null))
      this.resurrectable = await resurrectableSessions();
    const byPane = new Map<string, Marker[]>();
    for (const marker of await agentMarkers()) {
      const id = key(marker.zellijSession, String(marker.zellijPaneId));
      byPane.set(id, [...(byPane.get(id) ?? []), marker]);
    }
    const candidates = [
      process.cwd(),
      ...lines(
        (await run(["zoxide", "query", "-l"], { optional: true })) ?? "",
      ),
    ];
    for (const path of new Set(candidates)) {
      if (isDirectory(path) && !(await this.locate(path))) {
        const root = canonical(path);
        if (!this.locations.has(root))
          this.locations.set(root, {
            path: root,
            repo: null,
            branch: "directory",
          });
      }
    }
    const grouped = new Map<string, Target[]>();
    for (const [session, entries] of this.sessions) {
      for (const pane of entries ?? []) {
        if (pane.is_plugin || pane.exited || pane.is_selectable === false)
          continue;
        if (
          session === process.env.ZELLIJ_SESSION_NAME &&
          String(pane.id) === process.env.ZELLIJ_PANE_ID
        )
          continue;
        const matches = byPane.get(key(session, String(pane.id))) ?? [];
        const marker = matches.length === 1 ? matches[0] : undefined;
        const path =
          marker?.taskRoot || taskRoot(pane) || marker?.cwd || pane.pane_cwd;
        let root = await this.locate(path);
        if (root === null && isDirectory(path)) {
          root = canonical(path);
          if (!this.locations.has(root))
            this.locations.set(root, {
              path: root,
              repo: null,
              branch: "directory",
            });
        }
        const nativeAgent =
          Array.isArray(pane.program_status) &&
          pane.program_status.some((r) => object(r) && r.app);
        const activity = attention(pane, marker);
        const target: Target = {
          kind: marker || nativeAgent ? "agent" : "workspace",
          session,
          pane: pane.id,
          tab: pane.tab_id,
          path: root,
          identity: paneIdentity(pane),
          rank: activity.rank,
          activity,
          title: pane.title || pane.tab_name || `pane ${pane.id}`,
        };
        if (marker) {
          target.marker = {
            pid: marker.pid,
            stamp: marker.stamp,
            sessionId: marker.sessionId,
            sessionFile: marker.sessionFile,
          };
          target.title = `Pi · ${pane.tab_name || pane.title || marker.pid}`;
        }
        this.paneTargets.push(target);
        const group = key(root, session, pane.tab_id);
        grouped.set(group, [...(grouped.get(group) ?? []), target]);
      }
    }
    for (const group of grouped.values()) {
      const agents = group.filter((t) => t.kind === "agent");
      this.targets.push(...agents);
      const ordinary = group.filter((t) => t.kind !== "agent");
      const highest = ordinary.sort((a, b) => b.rank - a.rank)[0];
      if (highest && (!agents.length || highest.rank))
        this.targets.push(highest);
    }
    this.buildRows();
    return this;
  }

  workspacePanes(row: Row): Row[] {
    // Include editor/shell-only sessions even when ordinary panes are hidden from the tree.
    return this.paneTargets
      .filter(
        (t) =>
          (!row.session || t.session === row.session) &&
          (row.path ? t.path === row.path : Boolean(row.session)),
      )
      .map((t): Row => ({
        ...t,
        id: key(t.kind, t.path, t.session, t.pane),
      }));
  }

  agentRows(): Row[] {
    return orderRows(
      this.rows
        .filter((row) => row.kind === "agent")
        .map((row) => {
          const location = row.path ? this.locations.get(row.path) : undefined;
          const repo = location?.repo
            ? this.repos.get(location.repo)
            : undefined;
          const context = repo
            ? `${repo.name} / ${location!.branch}`
            : (row.path ?? "Unknown checkout");
          return {
            ...row,
            display: {
              prefix: "",
              name: row.title ?? "Agent",
              detail: `${context} · Pane ${row.pane}`,
            },
          };
        }),
    );
  }

  addRow(kind: Row["kind"], data: Omit<Row, "id" | "kind">): Row {
    const row = { ...data, kind, id: key(kind, data.path, data.session, data.pane) };
    this.rows.push(row);
    return row;
  }
  savedSession(root: string): string | undefined {
    const name = sessionNameForLocation(this, root);
    // A readable name is only an association when it identifies one known checkout.
    return this.locations.get(root)?.repo &&
      this.sessions.get(name) === null &&
      this.resurrectable.has(name) &&
      [...this.locations.keys()].filter(
        (path) => sessionNameForLocation(this, path) === name,
      ).length === 1
      ? name
      : undefined;
  }

  buildRows(): void {
    this.rows = [];
    const summary = (targets: Target[]) => {
      const target = [...targets].sort((a, b) => b.rank - a.rank)[0];
      return { activity: target?.activity, rank: target?.rank ?? 0, open: targets.length > 0 };
    };
    const locationRows = (root: string, prefix: string, context: string) => {
      const loc = this.locations.get(root)!;
      const targets = this.targets.filter((target) => target.path === root);
      const savedSession = this.savedSession(root);
      const search = loc.repo ? `${context} ${loc.branch}` : root;
      this.addRow(loc.repo ? "worktree" : "directory", {
        ...loc,
        ...summary(targets),
        savedSession,
        search,
        sessions: [...new Set([...targets.map((target) => target.session), ...(savedSession ? [savedSession] : [])])],
        display: { prefix, name: loc.repo ? loc.branch : root, detail: `${context} · ${root}` },
      });
      for (const target of targets.sort((a, b) =>
        compare(a.session, b.session) || a.tab - b.tab || a.pane - b.pane,
      )) {
        this.addRow(target.kind, {
          ...target,
          repo: loc.repo,
          open: true,
          search,
          display: {
            prefix: "    └─ ",
            name: target.title,
            detail: `Pane ${target.pane}`,
            context: `${context} / ${loc.branch} · ${target.session} / p${target.pane}`,
          },
        });
      }
    };
    for (const [common, repo] of [...this.repos].sort((a, b) =>
      compare(a[1].path, b[1].path),
    )) {
      this.addRow("repo", {
        path: repo.path,
        repo: common,
        ...summary(this.targets.filter((target) => target.path && repo.trees.includes(target.path))),
        display: { prefix: "", name: repo.name, detail: repo.path },
      });
      for (const root of repo.trees) locationRows(root, "  ├─ ", repo.name);
    }
    for (const [root, loc] of [...this.locations].sort((a, b) => compare(a[0], b[0]))) {
      if (loc.repo === null) locationRows(root, "▸ ", "Directories");
    }
    const mapped = new Set(this.targets.filter((target) => target.path).map((target) => target.session));
    for (const row of this.rows) if (row.savedSession) mapped.add(row.savedSession);
    const unmapped = new Set(this.targets.filter((target) => !target.path).map((target) => target.session));
    for (const [session, entries] of [...this.sessions].sort((a, b) => compare(a[0], b[0]))) {
      if (mapped.has(session) && !unmapped.has(session)) continue;
      const saved = entries === null && this.resurrectable.has(session);
      this.addRow("session", {
        session,
        status: entries !== null ? "live" : saved ? "♻ resurrectable" : "unavailable",
        open: entries !== null ? true : saved ? false : undefined,
        display: { prefix: "▸ ", name: session, detail: "Other sessions" },
      });
      for (const target of this.targets.filter((target) => target.session === session && !target.path)) {
        this.addRow(target.kind, {
          ...target,
          open: true,
          display: {
            prefix: "  └─ ",
            name: target.title,
            detail: `Pane ${target.pane}`,
            context: `${session} / p${target.pane}`,
          },
        });
      }
    }
    this.rows = orderRows(this.rows);
  }
}

const quote = (text: string) => `'${text.replaceAll("'", "'\\''")}'`;
async function refreshPicker(
  socket: string,
  action: string,
  signal: AbortSignal,
): Promise<void> {
  const deadline = performance.now() + 3000;
  while (!signal.aborted) {
    try {
      await new Promise<void>((resolve, reject) => {
        const req = request(
          {
            socketPath: socket,
            path: "/",
            method: "POST",
            signal,
            agent: false,
            headers: process.env.FZF_API_KEY
              ? { "x-api-key": process.env.FZF_API_KEY }
              : {},
          },
          (res) => {
            res.on("error", reject);
            res.on("end", () =>
              res.statusCode && res.statusCode >= 200 && res.statusCode < 300
                ? resolve()
                : reject(
                    new PickerError(
                      `fzf update failed: HTTP ${res.statusCode}`,
                    ),
                  ),
            );
            res.resume();
          },
        );
        req.on("error", reject);
        req.setTimeout(1000, () =>
          req.destroy(new PickerError("fzf update timed out")),
        );
        req.end(action);
      });
      return;
    } catch (error) {
      if (signal.aborted) return;
      // Cached metadata can finish before fzf has bound its private socket.
      if (
        !["ENOENT", "ECONNREFUSED"].includes(
          (error as NodeJS.ErrnoException).code ?? "",
        ) ||
        performance.now() >= deadline
      )
        throw error;
      await sleep(25, undefined, { signal });
    }
  }
}

export function filterCommand(input: string): string {
  // Match plain search text only: --ansi in filter mode strips colors from the returned display field.
  // Open first so an input-file error cannot masquerade as fzf's no-matches exit code.
  // Re-rank only rows whose repository name matches; the empty query keeps attention order.
  return (
    `unset FZF_DEFAULT_OPTS FZF_DEFAULT_OPTS_FILE; exec 3< ${quote(input)} || exit 2; query={q}; ` +
    `matches=$(fzf --tiebreak=index --delimiter='\\t' --nth=3 --filter="$query" <&3); result=$?; ` +
    `if [ "$result" -eq 1 ]; then exit 0; fi; [ "$result" -eq 0 ] || exit "$result"; ` +
    `if [ -z "$query" ]; then printf '%s\\n' "$matches"; exit 0; fi; ` +
    `preferred=$(printf '%s\\n' "$matches" | awk -F '\\t' 'NF == 4' | fzf --tiebreak=index --delimiter='\\t' --nth=4 --filter="$query"); result=$?; ` +
    `if [ "$result" -gt 1 ]; then exit "$result"; fi; ` +
    `{ [ -z "$preferred" ] || printf '%s\\n' "$preferred"; printf '%s\\n' "$matches"; } | awk -F '\\t' '!seen[$1]++'`
  );
}

export function toggleView(directory: string): string {
  const input = join(directory, "rows"),
    current = readlinkSync(input);
  if (!["tree", "agents"].includes(current))
    throw new PickerError("Invalid picker view");
  const next = current === "tree" ? "agents" : "tree",
    pending = join(directory, "rows.next");
  // Metadata reloads follow the same pointer; switching it atomically cannot restore the wrong view.
  rmSync(pending, { force: true });
  symlinkSync(next, pending);
  renameSync(pending, input);
  return `change-prompt(${next === "agents" ? "Agents" : "Tree"} > )+reload-sync:${filterCommand(input)}`;
}

export async function choose<T extends Choice | Row>(
  rows: T[],
  dmenu = false,
  prompt = "Repo / worktree > ",
  refresh?: Promise<void>,
  agents?: T[],
): Promise<[string, T | undefined]> {
  if (!rows.length) return ["cancel", undefined];
  if (dmenu) {
    const labels = new Map(
      rows.map((row, i) => [
        `${i + 1}. ${dmenuLabel(row)}`,
        row,
      ]),
    );
    const selected = await run(
      [
        "vicinae",
        "dmenu",
        "--navigation-title",
        "Zellij workspaces",
        "--placeholder",
        prompt,
      ],
      { input: [...labels.keys()].join("\n") + "\n", cancel: true, timeout: 0 },
    );
    return ["enter", labels.get((selected ?? "").replace(/\n+$/, ""))];
  }
  const choices = agents ? [...rows, ...agents] : rows;
  const directory = mkdtempSync(join(tmpdir(), "zs-"));
  const controller = new AbortController();
  let selected: string | null;
  try {
    const snapshot = join(directory, "preview.json"),
      inputFile = join(directory, "rows"),
      socket = join(directory, "fzf.sock");
    const input = (values = rows) =>
      values
        .map((r: Row) => {
          const label = renderRow(r);
          const search = clean(
            `${stripVTControlCharacters(label)} ${r.search ?? ""}`,
          );
          return `${r.id}\t${label}\t${search}${r.kind === "repo" && r.display ? `\t${clean(r.display.name)}` : ""}\n`;
        })
        .join("");
    const save = () => {
      const previews = JSON.stringify(
        Object.fromEntries(
          choices.map((r: Row) => [
            r.id,
            {
              text: rowPreview(r),
              path: r.kind === "worktree" ? r.path : undefined,
              branch: r.branch,
              pullRequests: r.pullRequests,
            },
          ]),
        ),
      );
      // A running preview must see either complete snapshot, never a half-written JSON file.
      const files = [
        [snapshot, previews],
        [agents ? join(directory, "tree") : inputFile, input()],
      ];
      if (agents) files.push([join(directory, "agents"), input(agents)]);
      for (const [path, data] of files) {
        writeFileSync(path + ".tmp", data);
        renameSync(path + ".tmp", path);
      }
    };
    save();
    if (agents) symlinkSync("tree", inputFile);
    void refresh
      ?.then(async () => {
        if (controller.signal.aborted) return;
        save();
        await refreshPicker(
          socket,
          `refresh-preview+reload-sync:${filterCommand(inputFile)}`,
          controller.signal,
        );
      })
      .catch((error) => {
        if (!controller.signal.aborted)
          console.error(
            `zs: PR display update unavailable: ${clean(error.message)}`,
          );
      });
    const helper = [
      process.execPath,
      "--experimental-strip-types",
      fileURLToPath(import.meta.url),
    ];
    const toggle = [...helper, "--toggle-view", directory].map(quote).join(" ");
    selected = await run(
      [
        "fzf",
        "--reverse",
        "--no-sort",
        "--ansi",
        "--pointer=▶",
        ...(process.env.NO_COLOR ? ["--color=bw"] : []),
        "--delimiter=\t",
        "--with-nth={2}",
        "--disabled",
        "--with-shell=bash --noprofile --norc -c",
        `--prompt=${agents ? "Tree > " : prompt}`,
        ...(refresh ? [`--listen=${socket}`] : []),
        ...(refresh || agents ? ["--track", "--id-nth=1"] : []),
        ...(agents ? ["--bind", `tab:transform:${toggle}`] : []),
        "--bind",
        `start:reload-sync:${filterCommand(inputFile)}`,
        "--bind",
        `change:reload-sync:${filterCommand(inputFile)}`,
        "--expect=ctrl-r,ctrl-d,ctrl-x",
        `--header=Enter open${agents ? " · Tab tree/agents" : ""} · Ctrl-R refresh · Ctrl-D kill / delete saved session · Ctrl-X remove worktree · Esc back`,
      ],
      { input: input(), cancel: true, timeout: 0 },
    );
  } finally {
    controller.abort();
    rmSync(directory, { recursive: true, force: true });
  }
  if (selected === null) return ["cancel", undefined];
  const output = lines(selected);
  return [
    output[0] || "enter",
    choices.find((r) => r.id === output[1]?.split("\t")[0]),
  ];
}

export async function selectedPane(
  row: Pick<Row, "session" | "pane" | "identity" | "marker">,
): Promise<void> {
  if (!row.session) throw new PickerError("Missing selected session");
  const entries = await panes(row.session);
  if (entries === null)
    throw new PickerError(
      "Session is unavailable; refusing implicit creation or resurrection",
    );
  if (row.pane === undefined) return;
  const candidates = entries.filter((p) => !p.is_plugin && p.id === row.pane);
  if (
    candidates.length !== 1 ||
    !isDeepStrictEqual(paneIdentity(candidates[0]), row.identity)
  ) {
    throw new PickerError(
      "Selected pane changed or closed; refresh before navigating",
    );
  }
  const marker = row.marker;
  if (
    marker &&
    !(await agentMarkers()).some(
      (m) =>
        m.zellijSession === row.session &&
        String(m.zellijPaneId) === String(row.pane) &&
        m.pid === marker.pid &&
        m.stamp === marker.stamp &&
        m.sessionId === marker.sessionId &&
        m.sessionFile === marker.sessionFile,
    )
  ) {
    throw new PickerError(
      "Selected agent identity changed; refresh before navigating",
    );
  }
}
export async function sourceContext(): Promise<Source | null> {
  const session = process.env.ZELLIJ_SESSION_NAME;
  if (!session) return null;
  const matches = ((await panes(session)) ?? []).filter(
    (p) =>
      !p.is_plugin && String(p.id) === process.env.ZELLIJ_PANE_ID && !p.exited,
  );
  if (matches.length !== 1) {
    throw new PickerError(
      "Cannot validate caller pane; reopen zs in the intended session",
    );
  }
  const pane = matches[0];
  return {
    session,
    pane: pane.id,
    identity: paneIdentity(pane),
    tab: pane.tab_id,
    floating: pane.is_floating === true,
  };
}
export async function hidePicker(source: Source | null): Promise<void> {
  if (!source?.floating || source.hidden) return;
  await selectedPane(source);
  // Exit 2 means the layer is already hidden in our fork.
  const result = await commands.capture([
    "zellij",
    `--session=${source.session}`,
    "action",
    "hide-floating-panes",
    "--tab-id",
    String(source.tab),
  ]);
  if (result.error || ![0, 2].includes(result.code!))
    throw new PickerError("Could not hide the source picker");
  source.hidden = true;
}
function sessionNameForLocation(catalog: Catalog, root: string): string {
  const readable = (value: string) =>
    value.replace(/[^a-zA-Z0-9_.-]+/g, "-").replace(/^[.-]+|[.-]+$/g, "") ||
    "workspace";
  const location = catalog.locations.get(root);
  if (!location?.repo) return readable(basename(root)).slice(0, 40);
  const repo = catalog.repos.get(location.repo)!;
  const name = readable(repo.name);
  if (root === repo.main) return name.slice(0, 40);
  const branch = location.worktree
    ?.find((field) => field.startsWith("branch refs/heads/"))
    ?.slice("branch refs/heads/".length);
  // Keep both readable components within the previous name budget for Unix socket paths.
  return `${name.slice(0, 25)}--${readable(branch ?? basename(root)).slice(0, 26)}`;
}
export async function newSessionName(path: string): Promise<string> {
  const catalog = new Catalog(),
    root = await catalog.locate(path);
  return sessionNameForLocation(catalog, root ?? canonical(path));
}
export type Destination =
  | { kind: "existing"; session: string }
  | { kind: "resurrect"; session: string }
  | { kind: "create"; session: string; path: string };

export async function resolveDestination(row: Row): Promise<Destination> {
  if (row.session !== undefined) {
    if (row.kind === "session" && row.pane === undefined && await panes(row.session) === null) {
      if (!(await resurrectableSessions()).has(row.session))
        throw new PickerError(
          "Session is unavailable and not confirmed as resurrectable; refresh the picker",
        );
      return { kind: "resurrect", session: row.session };
    }
    await selectedPane(row);
    return { kind: "existing", session: row.session };
  }

  if (!isDirectory(row.path))
    throw new PickerError("Checkout no longer exists; refresh the picker");
  const fresh = new Catalog();
  const root = await fresh.locate(row.path);
  const location = root ? fresh.locations.get(root) : undefined;
  if (
    row.kind === "worktree" &&
    row.worktree &&
    (root !== row.path ||
      location?.repo !== row.repo ||
      !isDeepStrictEqual(location?.worktree, row.worktree))
  )
    throw new PickerError("Checkout changed; refresh before navigating");

  const session = sessionNameForLocation(fresh, root ?? canonical(row.path));
  if (!(await sessionNames()).includes(session))
    return { kind: "create", session, path: row.path };

  // Discovery and navigation must consider the same cross-repository collisions.
  await fresh.discover();
  if (
    row.kind !== "worktree" ||
    !row.repo ||
    !row.worktree ||
    !root ||
    fresh.savedSession(root) !== session
  )
    throw new PickerError(
      "A session already uses this checkout name or its name is ambiguous; refresh instead of overwriting it",
    );
  return { kind: "resurrect", session };
}

export async function navigation(
  row: Row,
  source: Source | null,
  dmenu = false,
): Promise<void> {
  checkInterrupt();
  const destination = await resolveDestination(row);
  const session = destination.session;
  if (source) await selectedPane(source);
  const origin = source?.session;
  if (
    destination.kind === "resurrect" &&
    ((await panes(session)) !== null ||
      !(await resurrectableSessions()).has(session))
  ) {
    throw new PickerError(
      "Saved session changed or disappeared; refresh before resurrecting",
    );
  }
  if (!origin && destination.kind !== "create" && session.startsWith("-")) {
    throw new PickerError(
      "Cannot safely attach to a session whose name starts with '-'",
    );
  }
  checkInterrupt();
  if (source) await hidePicker(source);
  checkInterrupt();
  if (origin) {
    if (origin === session) {
      if (row.pane !== undefined)
        await action(origin, ["focus-pane-id", `terminal_${row.pane}`]);
    } else {
      const options = destination.kind === "create"
        ? ["--cwd", destination.path, "--layout", "project"]
        : [];
      if (row.pane !== undefined)
        options.push("--pane-id", `terminal_${row.pane}`);
      await action(origin, ["switch-session", ...options, "--", session]);
    }
    recordVisit(row);
    return;
  }
  const env = { ...process.env };
  for (const name of [
    "ZELLIJ",
    "ZELLIJ_SESSION_NAME",
    "ZELLIJ_PANE_ID",
    "PI_TASK_ROOT",
    "PI_TASK_REVIEW_STATE",
    "PI_TASK_SHARED",
  ])
    delete env[name];
  let command = destination.kind === "create"
    ? [
        "zellij",
        `--session=${session}`,
        "--new-session-with-layout",
        "project",
      ]
    : ["zellij", "attach", session];
  if (dmenu)
    command = ["kitty", "--directory", row.path || process.cwd(), ...command];
  const previousClients = new Set(
    destination.kind === "existing" ? await clients(session) : [],
  );
  const child = commands.launch(command, {
    cwd: row.path || undefined,
    env,
    detached: dmenu,
  });
  try {
    // Record arrival after attachment/focus, not when a long-lived terminal eventually exits.
    const deadline = performance.now() + 10000;
    while (true) {
      checkInterrupt();
      if (child.poll())
        throw new PickerError(
          "Terminal exited before navigation; inspect before retrying",
        );
      if ((await panes(session)) !== null) {
        const attached = (await clients(session)).some(
          (id) => !previousClients.has(id),
        );
        if (attached) {
          if (row.pane !== undefined) {
            await selectedPane(row);
            await action(session, [
              "focus-pane-id",
              `terminal_${row.pane}`,
            ]);
          }
          recordVisit(row);
          break;
        }
      }
      if (performance.now() >= deadline)
        throw new PickerError(
          "No client attached within 10 seconds; inspect before retrying",
        );
      await sleep(100);
    }
    if (!dmenu) {
      const result = await child.wait();
      if (result.code !== 0 || result.error)
        throw new PickerError(
          result.error?.message ?? "Zellij exited unsuccessfully",
        );
    }
  } finally {
    child.release();
  }
}

export async function removeWorktree(
  catalog: Catalog,
  row: Row,
  dmenu = false,
): Promise<void> {
  const path = row.path,
    common = row.repo;
  const original =
    typeof path === "string" ? catalog.locations.get(path) : undefined;
  if (
    row.kind !== "worktree" ||
    !path ||
    !common ||
    !row.worktree ||
    original?.repo !== common ||
    !isDeepStrictEqual(original.worktree, row.worktree)
  )
    throw new PickerError("Select a Git worktree row to remove its checkout");
  const inside = (value: unknown) =>
    typeof value === "string" &&
    isAbsolute(value) &&
    (canonical(value) === path || canonical(value).startsWith(path + sep));
  const validate = async () => {
    checkInterrupt();
    if (!isDirectory(path) || canonical(path) !== path)
      throw new PickerError(
        "Worktree moved or disappeared; refresh before removing",
      );
    const fresh = new Catalog();
    if (
      (await fresh.locate(path)) !== path ||
      fresh.locations.get(path)?.repo !== common
    ) {
      throw new PickerError(
        "Worktree repository changed; refresh before removing",
      );
    }
    const fields = fresh.locations.get(path)!.worktree ?? [];
    if (fields.some((f) => /^(locked|prunable)( |$)/.test(f)))
      throw new PickerError("Cannot remove a locked or prunable worktree");
    if (!isDeepStrictEqual(fields, row.worktree))
      throw new PickerError(
        "Worktree branch or HEAD changed; refresh before removing",
      );
    const gitDir = canonical(
      (await run([
        "git",
        "-C",
        path,
        "rev-parse",
        "--absolute-git-dir",
      ]))!.replace(/\n$/, ""),
    );
    if (gitDir === common)
      throw new PickerError("Cannot remove the main checkout");
    if (inside(process.cwd()) || inside(process.env.PI_TASK_ROOT))
      throw new PickerError(
        "Cannot remove the picker's current checkout or task root",
      );
    if ((await agentMarkers()).some((m) => inside(m.taskRoot) || inside(m.cwd)))
      throw new PickerError("Worktree is occupied by a live agent");
    for (const session of await sessionNames()) {
      const entries = await panes(session);
      if (entries === null)
        throw new PickerError(
          "Cannot verify session occupancy; leaving the worktree untouched",
        );
      for (const pane of entries) {
        if (pane.is_plugin || pane.exited) continue;
        if (inside(pane.pane_cwd) || inside(taskRoot(pane)))
          throw new PickerError("Worktree is occupied by a live Zellij pane");
        if (typeof pane.pane_cwd !== "string" || !isAbsolute(pane.pane_cwd)) {
          throw new PickerError(
            "Cannot verify a live pane's cwd; leaving the worktree untouched",
          );
        }
      }
    }
    // Git's normal removal can discard ignored files; protect them alongside tracked/untracked changes.
    const dirty = await run([
      "git",
      "--no-optional-locks",
      "-C",
      path,
      "status",
      "--porcelain=v1",
      "--untracked-files=all",
      "--ignored",
      "--ignore-submodules=none",
    ]);
    if (dirty)
      throw new PickerError(
        "Worktree has changes, untracked or ignored files; nothing removed",
      );
    const stat = statSync(path);
    return { gitDir, dev: stat.dev, ino: stat.ino };
  };
  const before = await validate();
  const [pressed, confirmed] = await choose(
    [
      { id: "cancel", label: "Cancel" },
      {
        id: "remove",
        label: clean(
          `REMOVE ${JSON.stringify(path)} — checkout only; keep branch and PR`,
        ),
        preview:
          clean(`Remove checkout: ${JSON.stringify(path)}`) +
          "\nKeep branch, GitHub PR and Pi review history. No force removal.",
      },
    ],
    dmenu,
    "Confirm worktree removal > ",
  );
  if (pressed !== "enter" || confirmed?.id !== "remove") return;
  if (!isDeepStrictEqual(before, await validate()))
    throw new PickerError(
      "Worktree directory changed during confirmation; refresh before removing",
    );
  checkInterrupt();
  await run(["git", "--git-dir", common, "worktree", "remove", "--", path], {
    timeout: 0,
  });
}

export async function deleteSession(
  catalog: Catalog,
  row: Row,
  dmenu = false,
): Promise<void> {
  const names = [
    ...new Set(
      catalog.rows
        .filter((r) =>
          row.session
            ? r.session === row.session
            : row.kind === "repo"
              ? r.repo === row.repo
              : r.path === row.path,
        )
        .flatMap((r) =>
          [r.session, r.savedSession].filter((name): name is string => !!name),
        ),
    ),
  ].sort(compare);
  if (!names.length)
    throw new PickerError("No existing session belongs to this row");
  const choices = names.map((name) => ({
    id: key(name),
    label: clean(
      `${name} — ${catalog.sessions.get(name) !== null ? "kill" : catalog.resurrectable.has(name) ? "♻ delete saved session" : "unavailable"}`,
    ),
    session: name,
  }));
  const [pressed, chosen] =
    choices.length > 1
      ? await choose(choices, dmenu, "Kill / delete which session? > ")
      : ["enter", choices[0]];
  if (pressed !== "enter" || !chosen) return;
  const name = chosen.session;
  if (!(await sessionNames()).includes(name))
    throw new PickerError("Session disappeared; nothing deleted");
  const before = catalog.sessions.get(name) ?? null,
    current = await panes(name);
  const identities = (entries: Pane[] | null) =>
    entries
      ?.map(paneIdentity)
      .sort((a, b) => Number(a.is_plugin) - Number(b.is_plugin) || a.id - b.id);
  if (!isDeepStrictEqual(identities(before), identities(current)))
    throw new PickerError(
      "Session changed since listing; refresh before deleting",
    );
  if (current === null) {
    if (
      !catalog.resurrectable.has(name) ||
      !(await resurrectableSessions()).has(name)
    ) {
      throw new PickerError(
        "Session is unavailable and not confirmed as resurrectable; nothing deleted",
      );
    }
  } else if ((await clients(name)).length > 1)
    throw new PickerError("Session has multiple clients; refusing kill");
  checkInterrupt();
  // Never force deletion: if a saved session becomes live, Zellij must refuse to kill it.
  await run([
    "zellij",
    current === null ? "delete-session" : "kill-session",
    "--",
    name,
  ]);
}

export async function main(args = process.argv.slice(2)): Promise<void> {
  const { values, positionals } = parseArgs({
    args,
    allowPositionals: true,
    options: {
      dmenu: { type: "boolean" },
      list: { type: "boolean" },
      preview: { type: "string" },
      "toggle-view": { type: "string" },
      help: { type: "boolean", short: "h" },
    },
  });
  if (values.help) {
    console.log(
      "zs [--dmenu] [--list]\nRepository/worktree navigation; Zellij owns attention state.\n--list: print sanitized rows without changing focus",
    );
    return;
  }
  if (values["toggle-view"]) {
    if (positionals.length)
      throw new PickerError("--toggle-view requires only the picker directory");
    console.log(toggleView(values["toggle-view"]));
    return;
  }
  if (values.preview) {
    if (positionals.length !== 1)
      throw new PickerError("--preview requires a snapshot and row ID");
    const snapshot = json(readFileSync(values.preview, "utf8"));
    if (!object(snapshot)) throw new PickerError("Invalid preview snapshot");
    const selected = snapshot[positionals[0]];
    if (!object(selected)) {
      console.log(typeof selected === "string" ? selected : "");
      return;
    }
    console.log(typeof selected.text === "string" ? selected.text : "");
    if (isDirectory(selected.path) && typeof selected.branch === "string")
      console.log(await gitPreview(selected.path, selected.branch));
    if (Array.isArray(selected.pullRequests) && selected.pullRequests.length) {
      const prs = selected.pullRequests.filter(
        (pr): pr is PullRequest =>
          object(pr) &&
          typeof pr.repository === "string" &&
          githubRepository(`https://github.com/${pr.repository}`) ===
            pr.repository &&
          Number.isSafeInteger(pr.number) &&
          Number(pr.number) > 0 &&
          typeof pr.title === "string" &&
          ["OPEN", "CLOSED", "MERGED"].includes(String(pr.state)) &&
          typeof pr.isDraft === "boolean",
      );
      console.log(await pullRequestPreview(prs));
    }
    return;
  }
  if (positionals.length)
    throw new PickerError("Unexpected positional arguments");
  const source = values.list ? null : await sourceContext();
  let githubController: AbortController | undefined,
    github: Promise<void> | undefined;
  try {
    while (true) {
      githubController?.abort();
      await github;
      const catalog = await new Catalog().discover();
      checkInterrupt();
      if (values.list) {
        console.log(catalog.rows.map(rowLabel).join("\n"));
        return;
      }
      githubController = new AbortController();
      const signal = githubController.signal;
      github = loadGithub(catalog.repos, catalog.rows, signal).catch((error) => {
        if (!signal.aborted && !interrupted)
          console.error(`zs: PR metadata unavailable: ${clean(error.message)}`);
      });
      if (values.dmenu) await github;
      checkInterrupt();
      const overview = values.dmenu
        ? catalog.rows
        : catalog.rows.filter((r) => r.kind !== "workspace");
      const agents = catalog.agentRows();
      let rows = overview;
      const history: Row[][] = [];
      const drill = (children: Row[]) => {
        if (children.length) {
          history.push(rows);
          rows = children;
        }
      };
      while (true) {
        const [pressed, selected] = await choose(
          rows,
          values.dmenu,
          undefined,
          github,
          agents,
        );
        checkInterrupt();
        let row = selected;
        if (pressed === "ctrl-r") break;
        if (!row) {
          if (history.length) {
            rows = history.pop()!;
            continue;
          }
          return;
        }
        if (pressed === "ctrl-d") {
          await deleteSession(catalog, row, values.dmenu);
          break;
        }
        if (pressed === "ctrl-x") {
          await removeWorktree(catalog, row, values.dmenu);
          break;
        }
        if (row.kind === "repo") {
          drill(
            overview.filter((r) => r.repo === row!.repo && r.kind !== "repo"),
          );
          continue;
        }
        if (
          row.kind === "worktree" ||
          row.kind === "directory" ||
          row.kind === "session"
        ) {
          const targets = catalog.workspacePanes(row);
          const sessions = [...new Set(targets.map((t) => t.session!))];
          if (sessions.length > 1) {
            drill(
              orderRows(
                sessions.map((session): Row => {
                  const summary = targets
                    .filter((t) => t.session === session)
                    .sort((a, b) => (b.rank ?? 0) - (a.rank ?? 0))[0];
                  return {
                    id: key("session", row!.path, session),
                    kind: "session",
                    session,
                    path: row!.path,
                    repo: row!.repo,
                    rank: summary.rank,
                    activity: summary.activity,
                    open: true,
                    display: {
                      prefix: "",
                      name: session,
                      detail: row!.path ?? "Other sessions",
                    },
                  };
                }),
              ),
            );
            continue;
          }
          if (sessions.length === 1) row = { ...row, session: sessions[0] };
        }
        await navigation(row, source, values.dmenu);
        return;
      }
    }
  } finally {
    githubController?.abort();
    await github;
    // Only the caller's verified floating layer, never a guessed title match.
    if (source && !source.hidden && (await panes(source.session)) !== null)
      await hidePicker(source);
  }
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  // Keep Node alive long enough to hide the picker after Ctrl-C, like the original CLI.
  const onInterrupt = () => {
    interrupted = true;
  };
  process.on("SIGINT", onInterrupt);
  main()
    .catch((error) => {
      if (!interrupted)
        console.error(
          `zs: ${clean(error instanceof Error ? error.message : error)}`,
        );
      process.exitCode = interrupted ? 130 : 1;
    })
    .finally(() => {
      process.off("SIGINT", onInterrupt);
    });
}
