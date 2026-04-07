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
import { handleFileMutation } from "./neovim.ts";
import { handleBash, handleUnknownTool } from "./bash.ts";
import { sendNotification } from "./notify.ts";

type GuardMode = "guarded" | "yolo";

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

  // ── Agent done notification ──────────────────────────────────────

  pi.on("agent_end", async (_event, ctx) => {
    sendNotification("pi", "Agent finished processing");
  });

  // ── Main tool_call gate ──────────────────────────────────────────

  pi.on("tool_call", async (event, ctx) => {
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
      return handleFileMutation(pi, event, ctx);
    }

    // Tier 3 & 4: Bash command review
    if (event.toolName === "bash") {
      return handleBash(event, ctx, approvedCommands);
    }

    // Unknown tools: timed approve
    return handleUnknownTool(event, ctx);
  });
}
