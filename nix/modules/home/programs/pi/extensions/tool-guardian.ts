/**
 * Tool Guardian Extension
 *
 * Unified review gate for all tool calls with tiered approval:
 *
 *   Tier 1 — Auto-allow: read-only tools (read, ls, find, grep)
 *   Tier 2 — Neovim diff: file mutations (edit, write) open in Neovim
 *   Tier 3 — Timed auto-approve: safe-looking bash commands (3s countdown)
 *   Tier 4 — Explicit approval: dangerous bash commands (rm, sudo, etc.)
 *
 * Desktop notifications with clickable actions are shown alongside TUI
 * prompts. Clicking Allow/Block on the notification resolves the review
 * just like picking in the TUI — whichever you interact with first wins.
 *
 * Remembers approved bash commands within a session so you only
 * approve once per unique command.
 *
 * Commands:
 *   /guardian       — Cycle mode: guarded → yolo → guarded
 *   /guardian-clear — Clear the session approval memory
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { spawn, spawnSync } from "node:child_process";
import {
  mkdtempSync,
  writeFileSync,
  unlinkSync,
  readFileSync,
  existsSync,
  rmdirSync,
} from "node:fs";
import { resolve, basename, join } from "node:path";
import { tmpdir } from "node:os";

// ── Pattern definitions ──────────────────────────────────────────────

/** Dangerous patterns that always require explicit approval */
const DANGEROUS_PATTERNS: RegExp[] = [
  /\brm\s+(-[^\s]*r|-[^\s]*f|--recursive|--force)/i,
  /\bsudo\b/i,
  /\b(chmod|chown)\b.*777/i,
  /\bmkfs\b/i,
  /\bdd\s+/i,
  />\s*\/dev\/sd/i,
  /\bnixos-rebuild\s+switch\b/i,
  /\bnixos-rebuild\s+boot\b/i,
  /\bcurl\b.*\|\s*(ba)?sh/i,
  /\bwget\b.*\|\s*(ba)?sh/i,
  /\beval\b/i,
  /\breboot\b/i,
  /\bshutdown\b/i,
  /\bsystemctl\s+(start|stop|restart|enable|disable)\b/i,
  /\bgit\s+push\b/i,
  /\bgit\s+push\s+--force/i,
  /\bgh\s+pr\s+merge\b/i,
  /\bgh\s+pr\s+create\b/i,
  /\bjira\s+issue\s+create\b/i,
];

/** Safe patterns that auto-run without any prompt */
const SAFE_PATTERNS: RegExp[] = [
  /^\s*ls(\s|$)/,
  /^\s*cat\s/,
  /^\s*head\s/,
  /^\s*tail\s/,
  /^\s*wc(\s|$)/,
  /^\s*echo\s/,
  /^\s*printf\s/,
  /^\s*pwd\s*$/,
  /^\s*which\s/,
  /^\s*type\s/,
  /^\s*file\s/,
  /^\s*stat\s/,
  /^\s*date\s*$/,
  /^\s*whoami\s*$/,
  /^\s*hostname\s*$/,
  /^\s*uname(\s|$)/,
  /^\s*env\s*$/,
  /^\s*printenv(\s|$)/,
  /^\s*grep\s/,
  /^\s*rg\s/,
  /^\s*find\s/,
  /^\s*fd\s/,
  /^\s*tree(\s|$)/,
  /^\s*du\s/,
  /^\s*df(\s|$)/,
  /^\s*diff\s/,
  /^\s*sort(\s|$)/,
  /^\s*uniq(\s|$)/,
  /^\s*cut\s/,
  /^\s*awk\s/,
  /^\s*sed\s.*['"]?s[/|]/,
  /^\s*git\s+(status|log|diff|show|branch|tag|stash\s+list|remote\s+-v)\b/,
  /^\s*git\s+ls-/,
  /^\s*gh\s+(pr|issue)\s+(list|view|status)\b/,
  /^\s*gh\s+repo\s+view\b/,
  /^\s*gh\s+search\s/,
  /^\s*gh\s+api\s/,
  /^\s*jira\s+(issue|sprint)\s+(list|view)\b/,
  /^\s*nix\s+(build|eval|flake\s+(show|check|metadata)|path-info|hash|log)\b/,
  /^\s*nixos-rebuild\s+(build|dry-build|dry-activate)\b/,
  /^\s*nix-store\s/,
  /^\s*nix-instantiate\s/,
  /^\s*man\s/,
  /^\s*--help\s*$/,
  /^\s*\S+\s+--help\s*$/,
  /^\s*\S+\s+-h\s*$/,
  /^\s*ddgr\s/,
  /^\s*pnpx\s+context7\s/,
  /^\s*cargo\s+(build|check|test|clippy|fmt\s+--check)\b/,
  /^\s*npm\s+(ls|list|outdated|audit)\b/,
  /^\s*node\s+-e\s/,
  /^\s*python3?\s+-c\s/,
  /^\s*jq\s/,
  /^\s*yq\s/,
  /^\s*realpath\s/,
  /^\s*basename\s/,
  /^\s*dirname\s/,
  /^\s*test\s/,
  /^\s*\[\s/,
];

// ── Desktop notification with actions ────────────────────────────────

interface NotifyHandle {
  /** Resolves with the action id when clicked; never resolves on dismiss */
  promise: Promise<string>;
  /** Kill the notification process */
  kill: () => void;
}

/**
 * Send a desktop notification with clickable action buttons.
 * Uses `notify-send --action` which blocks until an action is clicked
 * or the notification is dismissed.
 *
 * Returns a promise that resolves ONLY when an action is clicked.
 * If the notification is dismissed without clicking, the promise stays
 * pending forever — intended for use with Promise.race so the TUI
 * select can still win.
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
      // Only resolve when an action was actually clicked.
      // On dismiss/expire action is empty → promise stays pending,
      // so it can never win a Promise.race against the TUI.
      if (action) resolve(action);
    });
    proc.on("error", () => {
      // notify-send not available — never resolve, TUI wins
    });
  });

  return { promise, kill: () => proc.kill() };
}

/**
 * Race a TUI select dialog against a desktop notification with actions.
 * Whichever the user interacts with first wins; the other is cancelled.
 *
 * - If an action is clicked on the notification → that choice wins, TUI is aborted
 * - If the user picks in the TUI → that wins, notification process is killed
 * - If the TUI times out → returns undefined (auto-allow), notification is killed
 * - If the notification is dismissed without action → TUI continues unaffected
 */
async function selectWithNotification(
  ctx: any,
  tuiTitle: string,
  options: string[],
  notifTitle: string,
  notifBody: string,
  tuiOptions?: { timeout?: number },
): Promise<string | undefined> {
  const actions = options.map((label) => ({
    id: label.toLowerCase().replace(/\s+/g, "_"),
    label,
  }));

  // Map notification action ids back to TUI option labels
  const idToLabel = new Map(actions.map((a, i) => [a.id, options[i]]));

  const notif = notifyWithActions(notifTitle, notifBody, actions);
  const abortCtrl = new AbortController();

  type RaceResult =
    | { source: "tui"; choice: string | undefined }
    | { source: "notif"; choice: string | undefined };

  const tuiPromise: Promise<RaceResult> = ctx.ui
    .select(tuiTitle, options, {
      ...tuiOptions,
      signal: abortCtrl.signal,
    })
    .then((choice: string | undefined) => ({
      source: "tui" as const,
      choice,
    }));

  const notifPromise: Promise<RaceResult> = notif.promise.then(
    (actionId: string) => ({
      source: "notif" as const,
      choice: idToLabel.get(actionId),
    }),
  );

  const result = await Promise.race([tuiPromise, notifPromise]);

  // Clean up the loser
  if (result.source === "tui") {
    notif.kill();
  } else {
    abortCtrl.abort();
  }

  return result.choice;
}

// ── Neovim diff helpers ──────────────────────────────────────────────

function computeProposed(
  originalContent: string,
  oldText: string,
  newText: string,
): string | null {
  const idx = originalContent.indexOf(oldText);
  if (idx === -1) return null;
  return (
    originalContent.slice(0, idx) +
    newText +
    originalContent.slice(idx + oldText.length)
  );
}

function nvimRemoteSend(server: string, keys: string) {
  spawnSync("nvim", ["--server", server, "--remote-send", keys], {
    stdio: "ignore",
  });
}

// ── Bash command normalization for session memory ────────────────────

function normalizeCommand(cmd: string): string {
  return cmd.replace(/\s+/g, " ").trim();
}

// ── Extension ────────────────────────────────────────────────────────

type GuardMode = "guarded" | "yolo";

const TIMED_APPROVE_MS = 3000;

export default function (pi: ExtensionAPI) {
  let mode: GuardMode = "guarded";
  const approvedCommands = new Set<string>();

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Tool guardian loaded (guarded mode)", "info");
  });

  // ── Commands ─────────────────────────────────────────────────────

  pi.registerCommand("guardian", {
    description: "Cycle guardian mode: guarded → yolo → guarded",
    handler: async (_args, ctx) => {
      mode = mode === "guarded" ? "yolo" : "guarded";
      const emoji = mode === "guarded" ? "🛡️" : "🤠";
      ctx.ui.notify(`${emoji} Guardian: ${mode} mode`, "info");
    },
  });

  pi.registerCommand("guardian-clear", {
    description: "Clear remembered bash approvals for this session",
    handler: async (_args, ctx) => {
      const count = approvedCommands.size;
      approvedCommands.clear();
      ctx.ui.notify(`Cleared ${count} remembered approvals`, "info");
    },
  });

  // ── Main tool_call gate ──────────────────────────────────────────

  pi.on("tool_call", async (event, ctx) => {
    // Yolo mode: let everything through
    if (mode === "yolo") return undefined;
    if (!ctx.hasUI) return undefined;

    // Tier 1: Auto-allow read-only tools
    if (
      event.toolName === "read" ||
      event.toolName === "ls" ||
      event.toolName === "find" ||
      event.toolName === "grep"
    ) {
      return undefined;
    }

    // Tier 2: Neovim diff review for file mutations
    if (event.toolName === "edit" || event.toolName === "write") {
      return handleFileMutation(event, ctx);
    }

    // Tier 3 & 4: Bash command review
    if (event.toolName === "bash") {
      return handleBash(event, ctx);
    }

    // Unknown tools: timed approve
    return handleUnknownTool(event, ctx);
  });

  // ── Tier 2: Neovim diff review ──────────────────────────────────

  async function handleFileMutation(event: any, ctx: any) {
    let filePath: string;
    let originalContent = "";
    let proposedContent: string;

    if (isToolCallEventType("edit", event)) {
      filePath = event.input.path;
      const absolutePath = resolve(ctx.cwd, filePath);
      try {
        if (existsSync(absolutePath)) {
          originalContent = readFileSync(absolutePath, "utf-8");
        }
      } catch {}

      const result = computeProposed(
        originalContent,
        event.input.oldText,
        event.input.newText,
      );
      if (result === null) return undefined;
      proposedContent = result;
    } else if (isToolCallEventType("write", event)) {
      filePath = event.input.path;
      const absolutePath = resolve(ctx.cwd, filePath);
      try {
        if (existsSync(absolutePath)) {
          originalContent = readFileSync(absolutePath, "utf-8");
        }
      } catch {}
      proposedContent = event.input.content;
    } else {
      return undefined;
    }

    const fileName = basename(filePath);
    const absolutePath = resolve(ctx.cwd, filePath);

    const tmpDir = mkdtempSync(join(tmpdir(), "pi-guardian-"));
    const currentFile = join(tmpDir, `current_${fileName}`);
    const proposedFile = join(tmpDir, `proposed_${fileName}`);
    writeFileSync(currentFile, originalContent, "utf-8");
    writeFileSync(proposedFile, proposedContent, "utf-8");

    const nvimServer = process.env.NVIM;

    if (nvimServer) {
      const escString = (p: string) =>
        p.replace(/\\/g, "\\\\").replace(/ /g, "\\ ");

      const cmd = [
        `<C-\\><C-n>`,
        `:tabnew ${escString(currentFile)}<CR>`,
        `:setlocal readonly nomodifiable bufhidden=wipe<CR>`,
        `:diffthis<CR>`,
        `:vsplit ${escString(proposedFile)}<CR>`,
        `:diffthis<CR>`,
        `:wincmd l<CR>`,
      ].join("");

      nvimRemoteSend(nvimServer, cmd);

      // Race TUI select against desktop notification
      const choice = await selectWithNotification(
        ctx,
        `${fileName} — diff opened in Neovim tab`,
        ["Allow", "Block"],
        `📝 pi: reviewing ${fileName}`,
        `Diff opened in Neovim — click to respond`,
      );

      nvimRemoteSend(
        nvimServer,
        `<C-\\><C-n>:bwipeout! ${escString(currentFile)}<CR>:bwipeout! ${escString(proposedFile)}<CR>`,
      );

      if (choice === "Block" || choice === undefined) {
        cleanup(tmpDir, currentFile, proposedFile);
        ctx.abort();
        return { block: true, reason: "Blocked by user after reviewing diff" };
      }

      let userEdited = false;
      try {
        const afterContent = readFileSync(proposedFile, "utf-8");
        if (afterContent !== proposedContent) {
          writeFileSync(absolutePath, afterContent, "utf-8");
          userEdited = true;
        }
      } catch {}

      cleanup(tmpDir, currentFile, proposedFile);

      if (userEdited) {
        return {
          block: true,
          reason: `User edited ${fileName} directly. Re-read the file to see their changes before making further edits.`,
        };
      }

      return undefined;
    } else {
      // Standalone Neovim
      spawnSync(
        "nvim",
        [
          "-d",
          currentFile,
          proposedFile,
          "-c",
          `autocmd BufEnter ${currentFile.replace(/'/g, "''")} setlocal readonly nomodifiable`,
          "-c",
          "wincmd l",
          "-c",
          "autocmd QuitPre * qall",
        ],
        {
          stdio: "inherit",
          env: { ...process.env },
        },
      );

      let userEdited = false;
      try {
        const afterContent = readFileSync(proposedFile, "utf-8");
        if (afterContent !== proposedContent) {
          writeFileSync(absolutePath, afterContent, "utf-8");
          userEdited = true;
        }
      } catch {}

      cleanup(tmpDir, currentFile, proposedFile);

      if (userEdited) {
        return {
          block: true,
          reason: `User edited ${fileName} directly. Re-read the file to see their changes before making further edits.`,
        };
      }

      // Race TUI select against desktop notification
      const choice = await selectWithNotification(
        ctx,
        `${fileName}`,
        ["Allow", "Block"],
        `📝 pi: reviewing ${fileName}`,
        `Diff review complete — click to respond`,
      );

      if (choice === "Block" || choice === undefined) {
        ctx.abort();
        return { block: true, reason: "Blocked by user after reviewing diff" };
      }

      return undefined;
    }
  }

  // ── Tier 3 & 4: Bash review ─────────────────────────────────────

  async function handleBash(event: any, ctx: any) {
    if (!isToolCallEventType("bash", event)) return undefined;

    const command = event.input.command;
    const normalized = normalizeCommand(command);

    // Already approved this session
    if (approvedCommands.has(normalized)) return undefined;

    // Tier 1 for bash: safe patterns auto-allow
    if (SAFE_PATTERNS.some((p) => p.test(normalized))) {
      return undefined;
    }

    // Tier 4: Dangerous patterns require explicit approval (no timeout)
    if (DANGEROUS_PATTERNS.some((p) => p.test(normalized))) {
      const choice = await selectWithNotification(
        ctx,
        `⚠️  Dangerous command:\n\n  ${command}\n\nApprove?`,
        ["Allow", "Allow + Remember", "Block"],
        "⚠️ pi: dangerous command",
        truncateDisplay(command, 200),
      );

      if (choice === "Allow + Remember") {
        approvedCommands.add(normalized);
        return undefined;
      }
      if (choice === "Allow") {
        return undefined;
      }

      ctx.abort();
      return { block: true, reason: "Dangerous command blocked by user" };
    }

    // Tier 3: Everything else gets timed auto-approve
    const choice = await selectWithNotification(
      ctx,
      `🔍 bash: ${truncateDisplay(command, 120)}`,
      ["Allow", "Allow + Remember", "Block"],
      "🔍 pi: bash command",
      truncateDisplay(command, 200),
      { timeout: TIMED_APPROVE_MS },
    );

    // Timeout → auto-allow
    if (choice === undefined) return undefined;

    if (choice === "Allow + Remember") {
      approvedCommands.add(normalized);
      return undefined;
    }
    if (choice === "Allow") {
      return undefined;
    }

    ctx.abort();
    return { block: true, reason: "Bash command blocked by user" };
  }

  // ── Unknown tools: timed approve ─────────────────────────────────

  async function handleUnknownTool(event: any, ctx: any) {
    const choice = await selectWithNotification(
      ctx,
      `🔧 ${event.toolName}: review call?`,
      ["Allow", "Block"],
      `🔧 pi: ${event.toolName}`,
      `Tool call requires review`,
      { timeout: TIMED_APPROVE_MS },
    );

    if (choice === undefined) return undefined; // timeout → allow
    if (choice === "Allow") return undefined;

    ctx.abort();
    return { block: true, reason: `${event.toolName} blocked by user` };
  }
}

// ── Helpers ──────────────────────────────────────────────────────────

function cleanup(tmpDir: string, ...files: string[]) {
  for (const f of files) {
    try {
      unlinkSync(f);
    } catch {}
  }
  try {
    rmdirSync(tmpDir);
  } catch {}
}

function truncateDisplay(s: string, max: number): string {
  if (s.length <= max) return s;
  return s.slice(0, max - 1) + "…";
}
