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

import { execFileSync, spawn, spawnSync } from "node:child_process";
import { readdirSync, readFileSync, statSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { type ResponseData, uniqueId, watchForResponse } from "./nvim-ipc.ts";

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

export interface TmuxApprovalPayload {
  tool_name: string;
  display: string;
  dangerous: boolean;
  /** Raw command/code to syntax-highlight in the popup body. */
  command?: string;
  /** bat language for the command (default "bash"). */
  language?: string;
}

/**
 * Show a tool-call approval prompt as a tmux popup.
 *
 * Uses `display-popup -E` running a tiny bash menu that writes the chosen
 * decision to a response file. We watch the file for completion; cancel
 * closes the popup via `display-popup -C` so the TUI/notification surfaces
 * can win the race cleanly.
 *
 * Decisions match the nvim modal: "allow" | "allow_remember" | "block".
 */
export function requestTmuxApproval(payload: TmuxApprovalPayload): {
  promise: Promise<ResponseData>;
  cancel: () => void;
} {
  const id = uniqueId();
  const responseFile = join(tmpdir(), `pi-guardian-tmux-response-${id}.json`);
  const scriptFile = join(tmpdir(), `pi-guardian-tmux-script-${id}.sh`);

  // `read -n1` is a single-keystroke prompt — no Enter required, faster than
  // shelling out to fzf and works without extra deps. `a` = allow, `r` =
  // allow+remember, `b` = block. Anything else just closes the popup so the
  // other surfaces can still win.
  //
  // ANSI colors: 31=red, 33=yellow, 36=cyan, 32=green, 90=gray, 1=bold.
  // bat handles the command body; we wrap labels/keys manually so the
  // popup stays readable without 256-color terminfo gymnastics.
  const headerColor = payload.dangerous ? "1;31" : "1;36";
  const headerText = payload.dangerous
    ? `⚠️  DANGEROUS  ${payload.tool_name}`
    : `🔍  ${payload.tool_name}`;
  const bodyFile = join(tmpdir(), `pi-guardian-tmux-body-${id}`);
  writeFileSync(bodyFile, payload.command ?? payload.display, "utf-8");
  const lang = payload.language ?? "bash";

  const script = `#!/usr/bin/env bash
clear
printf '\x1b[${headerColor}m%s\x1b[0m\n\n' ${shellQuote(headerText)}
if command -v bat >/dev/null 2>&1; then
  bat --paging=never --style=plain --color=always --language=${shellQuote(lang)} ${shellQuote(bodyFile)} 2>/dev/null \
    || cat ${shellQuote(bodyFile)}
else
  cat ${shellQuote(bodyFile)}
fi
printf '\n\x1b[90m───\x1b[0m\n\n'
printf '  \x1b[1;32m[a]\x1b[0m allow    \x1b[1;33m[r]\x1b[0m allow + remember    \x1b[1;31m[b]\x1b[0m block    \x1b[90m[q]\x1b[0m dismiss\n\n'
printf '\x1b[1m> \x1b[0m'
read -n1 -s key
case "$key" in
  a) decision=allow ;;
  r) decision=allow_remember ;;
  b) decision=block ;;
  *) rm -f ${shellQuote(bodyFile)}; exit 0 ;;
esac
rm -f ${shellQuote(bodyFile)}
printf '{"decision":"%s"}' "$decision" > ${shellQuote(responseFile)}
`;
  writeFileSync(scriptFile, script, { mode: 0o700 });

  const { promise, cancel: cancelWatch } = watchForResponse(responseFile);

  // Spawn (not spawnSync) so the popup runs concurrently with the TUI race.
  const child = spawn(
    "tmux",
    [
      "display-popup",
      "-E",
      "-w",
      "70%",
      "-h",
      "30%",
      "-T",
      ` ${payload.dangerous ? "⚠️  approval" : "🔍  approval"} `,
      "bash",
      scriptFile,
    ],
    { stdio: "ignore", detached: false },
  );
  child.on("error", () => {});

  const cleanupScript = () => {
    try {
      unlinkSync(scriptFile);
    } catch {}
    try {
      unlinkSync(bodyFile);
    } catch {}
  };
  promise.then(cleanupScript, cleanupScript);

  return {
    promise,
    cancel: () => {
      cancelWatch();
      // -C closes any open popup on the current client. Cheap no-op if the
      // popup already exited.
      spawnSync("tmux", ["display-popup", "-C"], { stdio: "ignore" });
      cleanupScript();
    },
  };
}

function shellQuote(s: string): string {
  return `'${s.replace(/'/g, `'\\''`)}'`;
}
