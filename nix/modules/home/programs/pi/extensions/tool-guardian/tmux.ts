/**
 * Tmux integration — auto-detect a sibling Neovim pane and focus it.
 *
 * Resolution order:
 *   1. $NVIM (pi runs inside :terminal of nvim) — no pane switching
 *   2. tmux: scan panes in the current session for one running `nvim`,
 *      match its process tree against `$XDG_RUNTIME_DIR/nvim.<pid>.0`
 *      sockets, probe the socket, return socket + pane id
 *   3. null — caller falls back to standalone nvim
 *
 * The result is cached for the session. If a later probe of the cached
 * socket fails (nvim quit, was restarted), the cache is invalidated and
 * resolution runs again.
 */

import { execFileSync, spawnSync } from "node:child_process";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { resolve } from "node:path";

export interface NvimTarget {
  socket: string;
  /** tmux pane id (e.g. "%1"), or null when embedded via $NVIM. */
  paneId: string | null;
}

/** Probe a socket by asking nvim to evaluate a trivial expression. */
function probe(socket: string): boolean {
  const r = spawnSync("nvim", ["--server", socket, "--remote-expr", "1"], {
    stdio: ["ignore", "ignore", "ignore"],
    timeout: 1500,
  });
  return r.status === 0;
}

/** Read parent pid from /proc/<pid>/stat. Handles comms containing spaces/parens. */
function ppidOf(pid: number): number | null {
  try {
    const stat = readFileSync(`/proc/${pid}/stat`, "utf-8");
    const i = stat.lastIndexOf(")");
    const rest = stat.slice(i + 2).split(" ");
    const ppid = parseInt(rest[1] ?? "", 10);
    return Number.isFinite(ppid) ? ppid : null;
  } catch {
    return null;
  }
}

function isDescendantOf(pid: number, ancestor: number): boolean {
  let cur: number | null = pid;
  for (let i = 0; i < 64 && cur && cur > 1; i++) {
    if (cur === ancestor) return true;
    cur = ppidOf(cur);
  }
  return false;
}

/** Find candidate nvim sockets in well-known directories. */
function listNvimSockets(): { path: string; pid: number }[] {
  const dirs = [process.env.XDG_RUNTIME_DIR, "/tmp"].filter((d): d is string => !!d);
  const found: { path: string; pid: number }[] = [];
  for (const dir of dirs) {
    let entries: string[];
    try {
      entries = readdirSync(dir);
    } catch {
      continue;
    }
    for (const name of entries) {
      // Default nvim socket name is `nvim.<pid>.0`. nvf-wrapped nvim uses
      // `nvf.<pid>.0` (set via --listen in the wrapper). User-supplied paths
      // with different names won't match — those need PI_GUARDIAN_NVIM_SERVER
      // (not implemented; auto-detect covers the common case).
      const m = name.match(/^(?:nvim|nvf)\.(\d+)\.\d+$/);
      if (!m) continue;
      const path = resolve(dir, name);
      try {
        if (!statSync(path).isSocket()) continue;
      } catch {
        continue;
      }
      found.push({ path, pid: parseInt(m[1] ?? "0", 10) });
    }
  }
  return found;
}

/** Match `nvim`, `.nvim-wrapped` (nvf/mnw), and friends. */
const NVIM_CMD_RE = /^\.?n?vim(-wrapped)?$/i;

function debug(msg: string): void {
  if (!process.env.PI_GUARDIAN_DEBUG) return;
  process.stderr.write(`[guardian.tmux] ${msg}\n`);
}

function detectTmuxTarget(): NvimTarget | null {
  if (!process.env.TMUX) {
    debug("TMUX not set");
    return null;
  }

  let out: string;
  try {
    // `-s` = session-wide, so a hidden/detached nvim pane (e.g. after the
    // `prefix P` pi-toggle break-pane) is still discoverable.
    out = execFileSync(
      "tmux",
      [
        "list-panes",
        "-s",
        "-F",
        "#{pane_id} #{pane_pid} #{pane_current_command} #{pane_active}",
      ],
      { encoding: "utf-8", timeout: 1500, stdio: ["ignore", "pipe", "ignore"] },
    );
  } catch (err) {
    debug(`tmux list-panes failed: ${(err as Error).message}`);
    return null;
  }

  const sockets = listNvimSockets();
  debug(`panes:\n${out.trim()}`);
  debug(`sockets: ${sockets.map((s) => `${s.path}(pid=${s.pid})`).join(", ") || "(none)"}`);
  if (sockets.length === 0) return null;

  for (const line of out.trim().split("\n")) {
    const parts = line.split(" ");
    if (parts.length < 4) continue;
    const [paneId, pidStr, cmd, active] = parts;
    if (active === "1") continue; // skip pi's own pane
    if (!cmd || !NVIM_CMD_RE.test(cmd)) continue;
    const panePid = parseInt(pidStr ?? "0", 10);
    if (!panePid) continue;

    for (const s of sockets) {
      const match = s.pid === panePid || isDescendantOf(s.pid, panePid);
      if (!match) continue;
      if (probe(s.path)) {
        debug(`matched pane=${paneId} pid=${panePid} socket=${s.path}`);
        return { socket: s.path, paneId: paneId ?? null };
      }
      debug(`socket ${s.path} dead despite pid match`);
    }
  }
  debug("no matching nvim pane found");
  return null;
}

// undefined = unresolved, null = resolved-to-nothing
let cached: NvimTarget | null | undefined;

/**
 * Resolve a reachable nvim instance for guardian reviews/modals.
 * Returns null when no embedded nvim and no tmux sibling is available
 * — caller should fall back to standalone nvim.
 */
export function resolveNvimTarget(): NvimTarget | null {
  if (cached !== undefined) {
    if (cached === null) {
      // Re-attempt detection — user may have started nvim in another pane
      // after pi launched. Cheap when TMUX is unset (early return).
      const fresh = detectTmuxTargetIfNoEmbedded();
      if (fresh) cached = fresh;
      return cached;
    }
    if (probe(cached.socket)) return cached;
    cached = undefined;
  }

  const embedded = process.env.NVIM;
  if (embedded && probe(embedded)) {
    cached = { socket: embedded, paneId: null };
    return cached;
  }

  cached = detectTmuxTarget();
  return cached;
}

function detectTmuxTargetIfNoEmbedded(): NvimTarget | null {
  if (process.env.NVIM) return null;
  return detectTmuxTarget();
}

/** Focus a tmux pane. No-op when paneId is null or TMUX is unset. */
export function tmuxFocusPane(paneId: string | null): void {
  if (!paneId || !process.env.TMUX) return;
  spawnSync("tmux", ["select-pane", "-t", paneId], { stdio: "ignore" });
}

/** Return focus to the previously active tmux pane. */
export function tmuxFocusLastPane(): void {
  if (!process.env.TMUX) return;
  spawnSync("tmux", ["select-pane", "-l"], { stdio: "ignore" });
}
