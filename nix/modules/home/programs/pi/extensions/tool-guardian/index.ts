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
 * Re-registers edit/write tools with a `reason` parameter so the agent
 * must explain why each file change is needed.
 *
 * Review scope can be narrowed via environment variables:
 *   GUARDIAN_REVIEW_INCLUDE            — glob patterns to include
 *   GUARDIAN_REVIEW_EXCLUDE            — glob patterns to exclude
 *   GUARDIAN_REVIEW_INCLUDE_EXTENSIONS — file extensions to include
 *   GUARDIAN_REVIEW_EXCLUDE_EXTENSIONS — file extensions to exclude
 *
 * Commands:
 *   /guardian       — Cycle mode: guarded → yolo → guarded
 *   /guardian-clear — Clear the session approval memory
 */

import { readdirSync, rmdirSync, unlinkSync } from "node:fs";
import { join } from "node:path";
import {
  createEditToolDefinition,
  createWriteToolDefinition,
  type ExtensionAPI,
  type ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { handleBash, handleUnknownTool } from "./bash.ts";
import { handleFileMutation } from "./neovim.ts";
import { sendNotification } from "./notify.ts";
import { createReviewScope, hasFilters, isInReviewScope } from "./scope.ts";
import { GuardMode, isBlockedPath, READ_ONLY_TOOLS } from "./utils.ts";

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
              try {
                unlinkSync(join(tmpDir, f));
              } catch {}
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
        try {
          scan(join(cwd, entry.name));
        } catch {}
      }
    }
  } catch {}
}

const GUARDIAN_STATUS_KEY = "guardian";

function updateStatus(ctx: ExtensionContext, mode: GuardMode): void {
  if (!ctx.hasUI) return;
  const text =
    mode === GuardMode.Guarded
      ? ctx.ui.theme.fg("warning", "🛡️ guarded")
      : ctx.ui.theme.fg("dim", "🤠 yolo");
  ctx.ui.setStatus(GUARDIAN_STATUS_KEY, text);
}

function resolveExecutionRoot(ctx: ExtensionContext | undefined): string {
  if (ctx && typeof ctx.cwd === "string" && ctx.cwd.length > 0) return ctx.cwd;
  return process.cwd();
}

export default function (pi: ExtensionAPI) {
  let mode: GuardMode = GuardMode.Guarded;
  const approvedCommands = new Set<string>();
  const approvedTools = new Set<string>();
  const reviewScope = createReviewScope();

  // ── Re-register edit/write with `reason` parameter ───────────────

  const baseEdit = createEditToolDefinition(process.cwd());
  const baseWrite = createWriteToolDefinition(process.cwd());

  // Extend tool schemas with a `reason` property.
  // Typebox schemas are JSON Schema objects at runtime, so we spread and extend directly.
  const editParams = {
    ...baseEdit.parameters,
    properties: {
      ...baseEdit.parameters.properties,
      reason: {
        type: "string",
        description: "Why this edit is needed. Be specific and grounded in existing code.",
      },
    },
    required: [...(baseEdit.parameters.required ?? []), "reason"],
  };

  const writeParams = {
    ...baseWrite.parameters,
    properties: {
      ...baseWrite.parameters.properties,
      reason: {
        type: "string",
        description: "Why this write is needed. Be specific and grounded in existing code.",
      },
    },
    required: [...(baseWrite.parameters.required ?? []), "reason"],
  };

  pi.registerTool({
    ...baseEdit,
    description: `${baseEdit.description} Include a non-empty \`reason\` explaining why.`,
    promptSnippet:
      "Make precise file edits with exact text replacement. Include a `reason` for review.",
    promptGuidelines: [
      ...(baseEdit.promptGuidelines ?? []),
      "Always include a concrete `reason` for each edit — explain why the change is needed, not just what it does.",
    ],
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    parameters: editParams as any,
    prepareArguments(args: unknown) {
      if (!args || typeof args !== "object") return args;
      const input = args as Record<string, unknown>;
      const { oldText, newText, ...rest } = input;
      const edits = Array.isArray(rest.edits) ? rest.edits : [];
      if (typeof oldText === "string" && typeof newText === "string") {
        return { ...rest, edits: [...edits, { oldText, newText }] };
      }
      return args;
    },
    async execute(toolCallId, params, signal, onUpdate, toolCtx) {
      const nativeEdit = createEditToolDefinition(resolveExecutionRoot(toolCtx));
      return nativeEdit.execute(
        toolCallId,
        { path: params.path, edits: params.edits },
        signal,
        onUpdate,
        toolCtx,
      );
    },
  });

  pi.registerTool({
    ...baseWrite,
    description: `${baseWrite.description} Include a non-empty \`reason\` explaining why.`,
    promptGuidelines: [
      ...(baseWrite.promptGuidelines ?? []),
      "Always include a concrete `reason` for each write — explain why the change is needed, not just what it does.",
    ],
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    parameters: writeParams as any,
    async execute(toolCallId, params, signal, onUpdate, toolCtx) {
      const nativeWrite = createWriteToolDefinition(resolveExecutionRoot(toolCtx));
      return nativeWrite.execute(
        toolCallId,
        { path: params.path, content: params.content },
        signal,
        onUpdate,
        toolCtx,
      );
    },
  });

  // ── Lifecycle ────────────────────────────────────────────────────

  pi.on("session_start", async (_event, ctx) => {
    cleanupStaleTmpDirs(ctx.cwd);
    updateStatus(ctx, mode);
    const scopeInfo = hasFilters(reviewScope) ? " (scoped)" : "";
    ctx.ui.notify(`Tool guardian loaded (guarded mode${scopeInfo})`, "info");
  });

  // ── Commands ─────────────────────────────────────────────────────

  pi.registerCommand("guardian", {
    description: "Cycle guardian mode: guarded → yolo → guarded",
    handler: async (_args, ctx) => {
      mode = mode === GuardMode.Guarded ? GuardMode.Yolo : GuardMode.Guarded;
      updateStatus(ctx, mode);
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
    // Tier 0: Block access to sensitive files (always, even in yolo)
    const filePath =
      "input" in event && typeof event.input === "object" && event.input !== null
        ? (event.input as Record<string, unknown>).path
        : undefined;
    if (typeof filePath === "string") {
      const blocked = isBlockedPath(filePath);
      if (blocked) return { block: true, reason: blocked };
    }

    if (mode === GuardMode.Yolo) return undefined;
    if (!ctx.hasUI) return undefined;

    // Tier 1: Auto-allow read-only tools
    if (READ_ONLY_TOOLS.has(event.toolName)) {
      return undefined;
    }

    // Tier 2: Neovim diff review for file mutations
    if (event.toolName === "edit" || event.toolName === "write") {
      const mutPath =
        "input" in event && typeof event.input === "object" && event.input !== null
          ? (event.input as Record<string, unknown>).path
          : undefined;
      if (typeof mutPath === "string" && !isInReviewScope(mutPath, reviewScope)) {
        return undefined;
      }
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
