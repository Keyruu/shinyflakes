/**
 * Desktop notifications with focus-aware suppression.
 *
 * Notifications are only shown when the terminal running pi is NOT
 * focused — if you're already looking at the TUI, they'd be redundant.
 *
 * Focus detection uses `niri msg focused-window` (niri compositor).
 * Falls back to "not focused" on errors so notifications are sent
 * as a safe default on unsupported compositors.
 */

import { spawn, spawnSync } from "node:child_process";

// ── Focus detection ──────────────────────────────────────────────────

/** Cached terminal PID — found once by walking up the process tree */
let cachedTerminalPid: number | null | undefined = undefined;

const KNOWN_TERMINALS = new Set([
  "alacritty", ".alacritty-wr",
  "foot", "kitty", "wezterm", "wezterm-gui",
  "gnome-terminal", "konsole", "xterm",
]);

/**
 * Walk up the process tree from the current process to find the
 * terminal emulator PID (e.g. Alacritty, foot, kitty).
 */
function findTerminalPid(): number | null {
  try {
    let pid = process.ppid;
    for (let i = 0; i < 20; i++) {
      const ppidOut = spawnSync("ps", ["-o", "ppid=", "-p", String(pid)], {
        encoding: "utf-8",
        stdio: ["ignore", "pipe", "ignore"],
      });
      const commOut = spawnSync("ps", ["-o", "comm=", "-p", String(pid)], {
        encoding: "utf-8",
        stdio: ["ignore", "pipe", "ignore"],
      });

      const comm = commOut.stdout?.trim().toLowerCase() ?? "";
      if (KNOWN_TERMINALS.has(comm)) return pid;

      const ppid = parseInt(ppidOut.stdout?.trim() ?? "", 10);
      if (!ppid || ppid === pid || ppid <= 1) break;
      pid = ppid;
    }
  } catch {}
  return null;
}

/**
 * Check if the terminal running pi is currently the focused window.
 */
export function isTerminalFocused(): boolean {
  if (cachedTerminalPid === undefined) {
    cachedTerminalPid = findTerminalPid();
  }
  if (cachedTerminalPid === null) return false;

  try {
    const result = spawnSync("niri", ["msg", "focused-window"], {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 500,
    });
    const pidMatch = (result.stdout ?? "").match(/PID:\s*(\d+)/);
    if (pidMatch) {
      return parseInt(pidMatch[1], 10) === cachedTerminalPid;
    }
  } catch {}
  return false;
}

// ── Desktop notification with actions ────────────────────────────────

interface NotifyHandle {
  promise: Promise<string>;
  kill: () => void;
}

/**
 * Send a desktop notification with clickable action buttons.
 *
 * Uses `notify-send --action` which blocks until an action is clicked
 * or the notification is dismissed. The promise resolves ONLY on click;
 * on dismiss it stays pending so it can never win a Promise.race.
 */
function notifyWithActions(
  title: string,
  body: string,
  actions: { id: string; label: string }[],
): NotifyHandle {
  const args = [
    "--app-name=pi",
    ...actions.flatMap((a) => ["--action", `${a.id}=${a.label}`]),
    title,
    body,
  ];

  const proc = spawn("notify-send", args, {
    stdio: ["ignore", "pipe", "ignore"],
  });

  let stdout = "";
  proc.stdout.on("data", (chunk: Buffer) => {
    stdout += chunk.toString();
  });

  const promise = new Promise<string>((resolve) => {
    proc.on("close", () => {
      const action = stdout.trim();
      if (action) resolve(action);
    });
    proc.on("error", () => {});
  });

  return { promise, kill: () => proc.kill() };
}

/**
 * Send a simple (non-interactive) desktop notification.
 * Only shown when the terminal is not focused.
 */
export function sendNotification(title: string, body: string): void {
  if (isTerminalFocused()) return;
  try {
    spawn("notify-send", ["--app-name=pi", title, body], {
      stdio: "ignore",
    });
  } catch {}
}

// ── TUI + notification racing ────────────────────────────────────────

/**
 * Race a TUI select dialog against a desktop notification with actions.
 * Whichever the user interacts with first wins; the other is cancelled.
 *
 * When the terminal is focused the notification is skipped entirely.
 */
export async function selectWithNotification(
  ctx: any,
  tuiTitle: string,
  options: string[],
  notifTitle: string,
  notifBody: string,
  tuiOptions?: { timeout?: number; signal?: AbortSignal },
): Promise<string | undefined> {
  const actions = options.map((label) => ({
    id: label.toLowerCase().replace(/\s+/g, "_"),
    label,
  }));
  const idToLabel = new Map(actions.map((a, i) => [a.id, options[i]]));

  const notif = isTerminalFocused()
    ? null
    : notifyWithActions(notifTitle, notifBody, actions);
  const abortCtrl = new AbortController();

  // If an external signal aborts, also abort our internal controller and kill notification
  if (tuiOptions?.signal) {
    if (tuiOptions.signal.aborted) {
      abortCtrl.abort();
      notif?.kill();
    } else {
      tuiOptions.signal.addEventListener("abort", () => {
        abortCtrl.abort();
        notif?.kill();
      }, { once: true });
    }
  }

  type RaceResult =
    | { source: "tui"; choice: string | undefined }
    | { source: "notif"; choice: string | undefined };

  const tuiPromise: Promise<RaceResult> = ctx.ui
    .select(tuiTitle, options, { ...tuiOptions, signal: abortCtrl.signal })
    .then((choice: string | undefined) => ({
      source: "tui" as const,
      choice,
    }));

  if (notif) {
    const notifPromise: Promise<RaceResult> = notif.promise.then(
      (actionId: string) => ({
        source: "notif" as const,
        choice: idToLabel.get(actionId),
      }),
    );

    const result = await Promise.race([tuiPromise, notifPromise]);

    if (result.source === "tui") {
      notif.kill();
    } else {
      abortCtrl.abort();
    }

    return result.choice;
  }

  const result = await tuiPromise;
  return result.choice;
}
