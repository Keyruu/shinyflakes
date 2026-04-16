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
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import { FOCUS_ACTIONS } from "./utils.ts";

// ── Window identification ─────────────────────────────────────────────

/** Find the niri window ID of the currently focused window. */
function findFocusedWindowId(): string | null {
  try {
    const result = spawnSync("niri", ["msg", "focused-window"], {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 500,
    });
    const idMatch = (result.stdout ?? "").match(/^Window ID\s+(\d+)/m);
    return idMatch?.[1] ?? null;
  } catch {}
  return null;
}

/**
 * Resolved eagerly at module load time — pi is always launched from
 * a focused terminal, so the currently focused window IS our terminal.
 * Lazy init would be wrong: first use happens when a notification fires,
 * at which point the user has likely switched away.
 */
const terminalWindowId: string | null = findFocusedWindowId();

/**
 * Check if the terminal running pi is currently the focused window.
 */
export function isTerminalFocused(): boolean {
  if (terminalWindowId === null) return false;

  try {
    const result = spawnSync("niri", ["msg", "focused-window"], {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 500,
    });
    const idMatch = (result.stdout ?? "").match(/^Window ID\s+(\d+)/m);
    return idMatch?.[1] === terminalWindowId;
  } catch {}
  return false;
}

// ── Focus terminal window ────────────────────────────────────────────

/**
 * Focus the terminal window running pi via niri compositor.
 * Uses the cached niri window ID.
 */
export function focusTerminal(): void {
  if (terminalWindowId === null) return;

  spawn("niri", ["msg", "action", "focus-window", "--id", terminalWindowId], {
    stdio: "ignore",
  });
}

// ── Notification helpers ─────────────────────────────────────────────

/**
 * Spawn `notify-send` and collect its stdout. Returns a promise that
 * resolves with the action ID when the user clicks, or never resolves
 * on dismiss. Also exposes `kill()` to cancel early.
 */
function spawnNotifySend(args: string[]): {
  promise: Promise<string>;
  kill: () => void;
} {
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
 *
 * A `default` action is included so clicking the notification body
 * focuses the terminal without selecting any action.
 */
function notifyWithActions(
  title: string,
  body: string,
  actions: { id: string; label: string }[],
): NotifyHandle {
  const args = [
    "--app-name=pi",
    "--action",
    "default=",
    ...actions.flatMap((a) => ["--action", `${a.id}=${a.label}`]),
    title,
    body,
  ];

  const { promise: rawPromise, kill } = spawnNotifySend(args);

  const promise = new Promise<string>((resolve) => {
    rawPromise.then((action) => {
      if (action === "default") {
        focusTerminal();
      } else {
        resolve(action);
      }
    });
  });

  return { promise, kill };
}

/**
 * Send a simple (non-interactive) desktop notification.
 * Only shown when the terminal is not focused. Clicking the
 * notification body focuses the terminal.
 */
export function sendNotification(title: string, body: string): void {
  if (isTerminalFocused()) return;
  try {
    const { promise } = spawnNotifySend(["--app-name=pi", "--action", "default=", title, body]);
    promise.then((action) => {
      if (action === "default") focusTerminal();
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
  ctx: ExtensionContext,
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

  const notif = isTerminalFocused() ? null : notifyWithActions(notifTitle, notifBody, actions);
  const abortCtrl = new AbortController();

  // If an external signal aborts, also abort our internal controller and kill notification
  if (tuiOptions?.signal) {
    if (tuiOptions.signal.aborted) {
      abortCtrl.abort();
      notif?.kill();
    } else {
      tuiOptions.signal.addEventListener(
        "abort",
        () => {
          abortCtrl.abort();
          notif?.kill();
        },
        { once: true },
      );
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
    const notifPromise: Promise<RaceResult> = notif.promise.then((actionId: string) => ({
      source: "notif" as const,
      choice: idToLabel.get(actionId),
    }));

    const result = await Promise.race([tuiPromise, notifPromise]);

    if (result.source === "tui") {
      notif.kill();
    } else {
      if (FOCUS_ACTIONS.has(result.choice ?? "")) focusTerminal();
      abortCtrl.abort();
    }

    return result.choice;
  }

  const result = await tuiPromise;
  return result.choice;
}
