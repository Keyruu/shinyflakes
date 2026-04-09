/**
 * Bash command review with tiered approval.
 *
 *   - Safe patterns → auto-allow
 *   - Dangerous patterns → explicit approval (no timeout)
 *   - Everything else → timed auto-approve (3s countdown)
 *
 * Remembers approved commands within a session.
 */

import type { ExtensionContext, ToolCallEvent } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { DANGEROUS_PATTERNS, SAFE_PATTERNS } from "./patterns.ts";
import { selectWithNotification } from "./notify.ts";
import { type BlockResult, isBlockedPath, ReviewAction, truncate } from "./utils.ts";

const TIMED_APPROVE_MS = 5000;

function normalizeCommand(cmd: string): string {
  return cmd.replace(/\s+/g, " ").trim();
}

/**
 * Resolve a review choice into either a block result or undefined (allow).
 * Handles Allow, Allow + Remember, Block, and timeout (undefined → allow).
 */
function resolveChoice(
  choice: string | undefined,
  ctx: ExtensionContext,
  normalized: string,
  approvedCommands: Set<string>,
  blockReason: string,
): BlockResult | undefined {
  if (choice === undefined) return undefined; // timeout → allow
  if (choice === ReviewAction.AllowRemember) {
    approvedCommands.add(normalized);
    return undefined;
  }
  if (choice === ReviewAction.Allow) return undefined;

  ctx.abort();
  return { block: true, reason: blockReason };
}

export async function handleBash(
  event: ToolCallEvent,
  ctx: ExtensionContext,
  approvedCommands: Set<string>,
): Promise<BlockResult | undefined> {
  if (!isToolCallEventType("bash", event)) return undefined;

  const command = event.input.command;
  const normalized = normalizeCommand(command);

  // Check if the command references any blocked paths
  const blockedReason = isBlockedPath(command);
  if (blockedReason) return { block: true, reason: blockedReason };

  if (approvedCommands.has(normalized)) return undefined;

  if (SAFE_PATTERNS.some((p) => p.test(normalized))) {
    return undefined;
  }

  // Dangerous: explicit approval, no timeout
  if (DANGEROUS_PATTERNS.some((p) => p.test(normalized))) {
    const choice = await selectWithNotification(
      ctx,
      `⚠️  Dangerous command:\n\n  ${command}\n\nApprove?`,
      [ReviewAction.Allow, ReviewAction.AllowRemember, ReviewAction.Block],
      "⚠️ pi: dangerous command",
      truncate(command, 200),
    );

    return resolveChoice(choice, ctx, normalized, approvedCommands, "Dangerous command blocked by user");
  }

  // Everything else: timed auto-approve
  const choice = await selectWithNotification(
    ctx,
    `🔍 bash: ${truncate(command, 120)}`,
    [ReviewAction.Allow, ReviewAction.AllowRemember, ReviewAction.Block],
    "🔍 pi: bash command",
    truncate(command, 200),
    { timeout: TIMED_APPROVE_MS },
  );

  return resolveChoice(choice, ctx, normalized, approvedCommands, "Bash command blocked by user");
}

export async function handleUnknownTool(
  event: ToolCallEvent,
  ctx: ExtensionContext,
  approvedTools: Set<string>,
): Promise<BlockResult | undefined> {
  if (approvedTools.has(event.toolName)) return undefined;

  const choice = await selectWithNotification(
    ctx,
    `🔧 ${event.toolName}: review call?`,
    [ReviewAction.Allow, ReviewAction.AllowRemember, ReviewAction.Block],
    `🔧 pi: ${event.toolName}`,
    `Tool call requires review`,
    { timeout: TIMED_APPROVE_MS },
  );

  return resolveChoice(choice, ctx, event.toolName, approvedTools, `${event.toolName} blocked by user`);
}
