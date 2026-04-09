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
 * Desktop notifications are shown only when the terminal is not focused.
 * Clicking Allow/Block on a notification resolves the review just like
 * the TUI — whichever you interact with first wins.
 *
 * AI comments: when reviewing a diff in Neovim you can add comments
 * starting with `ai:` to steer the agent. On Allow the file is written
 * as-is and the agent is told to follow the instructions and remove them.
 *
 * Also sends a "finished" desktop notification when the agent completes
 * a prompt (only when the terminal is not focused).
 *
 * Commands:
 *   /guardian       — Cycle mode: guarded → yolo → guarded
 *   /guardian-clear — Clear the session approval memory
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readdirSync, rmdirSync, unlinkSync } from "node:fs";
import { join } from "node:path";
import { handleFileMutation } from "./neovim.ts";
import { handleBash, handleUnknownTool } from "./bash.ts";
import { sendNotification } from "./notify.ts";
import { GuardMode, READ_ONLY_TOOLS } from "./utils.ts";

/**
 * Remove leftover `.pi-guardian-*` temp dirs from previous sessions
 * that may not have been cleaned up (e.g. crash mid-review).
 */
function cleanupStaleTmpDirs(cwd: string): void {
  try {
    const scan = (dir: string) => {
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        if (entry.isDirectory() && entry.name.startsWith(".pi-guardian-")) {
          const tmpDir = join(dir, entry.name);
          try {
            for (const f of readdirSync(tmpDir)) {
              try { unlinkSync(join(tmpDir, f)); } catch {}
            }
            rmdirSync(tmpDir);
          } catch {}
        }
      }
    };
    scan(cwd);
    // Also scan subdirectories one level deep (where most edits happen)
    for (const entry of readdirSync(cwd, { withFileTypes: true })) {
      if (entry.isDirectory() && !entry.name.startsWith(".")) {
        try { scan(join(cwd, entry.name)); } catch {}
      }
    }
  } catch {}
}

export default function (pi: ExtensionAPI) {
  let mode = GuardMode.Guarded;
  const approvedCommands = new Set<string>();
  const approvedTools = new Set<string>();

  pi.on("session_start", async (_event, ctx) => {
    cleanupStaleTmpDirs(ctx.cwd);
    ctx.ui.notify("Tool guardian loaded (guarded mode)", "info");
  });

  // ── Commands ─────────────────────────────────────────────────────

  pi.registerCommand("guardian", {
    description: "Cycle guardian mode: guarded → yolo → guarded",
    handler: async (_args, ctx) => {
      mode = mode === GuardMode.Guarded ? GuardMode.Yolo : GuardMode.Guarded;
      const emoji = mode === GuardMode.Guarded ? "🛡️" : "🤠";
      ctx.ui.notify(`${emoji} Guardian: ${mode} mode`, "info");
    },
  });

  pi.registerCommand("guardian-clear", {
    description: "Clear remembered bash approvals for this session",
    handler: async (_args, ctx) => {
      const count = approvedCommands.size + approvedTools.size;
      approvedCommands.clear();
      approvedTools.clear();
      ctx.ui.notify(`Cleared ${count} remembered approvals`, "info");
    },
  });

  // ── Agent done notification ──────────────────────────────────────

  pi.on("agent_end", async (_event, _ctx) => {
    sendNotification("pi", "Agent finished processing");
  });

  // ── Main tool_call gate ──────────────────────────────────────────

  pi.on("tool_call", async (event, ctx) => {
    if (mode === GuardMode.Yolo) return undefined;
    if (!ctx.hasUI) return undefined;

    // Tier 1: Auto-allow read-only tools
    if (READ_ONLY_TOOLS.has(event.toolName)) {
      return undefined;
    }

    // Tier 2: Neovim diff review for file mutations
    if (event.toolName === "edit" || event.toolName === "write") {
      return handleFileMutation(pi, event, ctx);
    }

    // Tier 3 & 4: Bash command review
    if (event.toolName === "bash") {
      return handleBash(event, ctx, approvedCommands);
    }

    // Unknown tools: timed approve
    return handleUnknownTool(event, ctx, approvedTools);
  });
}
