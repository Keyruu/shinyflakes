/**
 * Tool Guardian Extension
 *
 * Unified review gate for all tool calls with tiered approval:
 *
 *   Tier 1 — Auto-allow: read-only tools (read, ls, find, grep)
 *   Tier 2 — Neovim diff: file mutations (edit, write) open in Neovim
 *   Tier 3 — Timed auto-approve: safe-looking bash commands (5s countdown)
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

import { existsSync, readdirSync, readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import {
  createEditToolDefinition,
  createWriteToolDefinition,
  type ExtensionAPI,
  type ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { handleBash, handleUnknownTool } from "./bash.ts";
import { reviewFileDiff } from "./neovim.ts";
import { sendNotification } from "./notify.ts";
import { createReviewScope, hasFilters, isInReviewScope } from "./scope.ts";
import { GuardMode, isBlockedPath, READ_ONLY_TOOLS } from "./utils.ts";

/**
 * Remove leftover pi-guardian payload/response files from /tmp.
 */
function cleanupStaleTmpFiles(): void {
  try {
    const tmp = tmpdir();
    for (const entry of readdirSync(tmp)) {
      if (entry.startsWith("pi-guardian-")) {
        try {
          unlinkSync(`${tmp}/${entry}`);
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

export default function (pi: ExtensionAPI) {
  let mode: GuardMode = GuardMode.Guarded;
  const approvedCommands = new Set<string>();
  const approvedTools = new Set<string>();
  const reviewScope = createReviewScope();

  // ── Re-register edit/write with `reason` parameter ───────────────

  const baseEdit = createEditToolDefinition(process.cwd());
  const baseWrite = createWriteToolDefinition(process.cwd());

  // Extend tool schemas with a `reason` property.
  // These are JSON Schema objects at runtime (from Typebox). We spread
  // and extend directly. The `as any` casts are needed because the
  // extended shape no longer matches Typebox's Static<T> inference —
  // runtime behavior is correct but the type system can't verify it.
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

  /**
   * Run the native tool, then show a diff review if in scope.
   * On reject, restore the original file content.
   */
  async function executeWithReview(
    toolName: "edit" | "write",
    toolCallId: string,
    params: Record<string, unknown>,
    signal: AbortSignal | undefined,
    onUpdate: unknown,
    ctx: ExtensionContext,
  ) {
    const filePath = params.path as string;
    const absolutePath = resolve(ctx.cwd, filePath);
    const reason = params.reason as string | undefined;

    // Snapshot before native tool writes
    let originalContent = "";
    try {
      if (existsSync(absolutePath)) originalContent = readFileSync(absolutePath, "utf-8");
    } catch {}

    // Run native tool (writes to disk). Split by tool type so
    // TypeScript can narrow the parameter shapes without `as any`.
    // biome-ignore lint/suspicious/noImplicitAnyLet: result type varies by branch (EditToolDetails | undefined)
    let result;
    if (toolName === "edit") {
      const def = createEditToolDefinition(ctx.cwd);
      result = await def.execute(
        toolCallId,
        {
          path: params.path as string,
          edits: params.edits as Array<{ oldText: string; newText: string }>,
        },
        signal,
        onUpdate as Parameters<typeof def.execute>[3],
        ctx,
      );
    } else {
      const def = createWriteToolDefinition(ctx.cwd);
      result = await def.execute(
        toolCallId,
        { path: params.path as string, content: params.content as string },
        signal,
        onUpdate as Parameters<typeof def.execute>[3],
        ctx,
      );
    }

    // Read what was actually written
    let proposedContent = originalContent;
    try {
      if (existsSync(absolutePath)) proposedContent = readFileSync(absolutePath, "utf-8");
    } catch {}

    // Skip review if: yolo mode, no UI, content unchanged (edit error), or out of scope
    if (mode === GuardMode.Yolo) return result;
    if (!ctx.hasUI) return result;
    if (proposedContent === originalContent) return result;
    if (!isInReviewScope(filePath, reviewScope)) return result;

    // Show diff review
    const reviewResult = await reviewFileDiff(pi, ctx, {
      filePath,
      absolutePath,
      originalContent,
      proposedContent,
      reason,
    });

    if (reviewResult && "block" in reviewResult && reviewResult.block) {
      // Restore original content
      try {
        writeFileSync(absolutePath, originalContent, "utf-8");
      } catch {}
      return {
        content: [{ type: "text" as const, text: reviewResult.reason }],
        details: undefined,
      };
    }

    // Accepted (possibly with user edits — file already has final content)
    if (reviewResult && "accepted" in reviewResult) {
      return {
        content: [{ type: "text" as const, text: reviewResult.message }],
        details: undefined,
      };
    }

    return result;
  }

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
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    async execute(toolCallId, params, signal, onUpdate, ctx): Promise<any> {
      return executeWithReview("edit", toolCallId, params, signal, onUpdate, ctx);
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
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    async execute(toolCallId, params, signal, onUpdate, ctx): Promise<any> {
      return executeWithReview("write", toolCallId, params, signal, onUpdate, ctx);
    },
  });

  // ── Lifecycle ────────────────────────────────────────────────────

  pi.on("session_start", async (_event, ctx) => {
    cleanupStaleTmpFiles();
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

  pi.on("tool_call", async (event, _ctx) => {
    // Block access to sensitive files (always, even in yolo)
    const filePath =
      "input" in event && typeof event.input === "object" && event.input !== null
        ? (event.input as Record<string, unknown>).path
        : undefined;
    if (typeof filePath === "string") {
      const blocked = isBlockedPath(filePath);
      if (blocked) return { block: true, reason: blocked };
    }

    if (mode === GuardMode.Yolo) return undefined;
    if (!_ctx.hasUI) return undefined;

    // Auto-allow read-only tools
    if (READ_ONLY_TOOLS.has(event.toolName)) return undefined;

    // edit/write review is handled in execute() — let them through
    if (event.toolName === "edit" || event.toolName === "write") return undefined;

    // Bash command review
    if (event.toolName === "bash") {
      return handleBash(event, _ctx, approvedCommands);
    }

    // Unknown tools: timed approve
    return handleUnknownTool(event, _ctx, approvedTools);
  });
}
