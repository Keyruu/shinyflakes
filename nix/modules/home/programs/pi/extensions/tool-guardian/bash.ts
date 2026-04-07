/**
 * Bash command review with tiered approval.
 *
 *   - Safe patterns → auto-allow
 *   - Dangerous patterns → explicit approval (no timeout)
 *   - Everything else → timed auto-approve (3s countdown)
 *
 * Remembers approved commands within a session.
 */

import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { DANGEROUS_PATTERNS, SAFE_PATTERNS } from "./patterns.ts";
import { selectWithNotification } from "./notify.ts";
import { truncate } from "./utils.ts";

const TIMED_APPROVE_MS = 3000;

function normalizeCommand(cmd: string): string {
  return cmd.replace(/\s+/g, " ").trim();
}

export async function handleBash(
  event: any,
  ctx: any,
  approvedCommands: Set<string>,
): Promise<{ block: true; reason: string } | undefined> {
  if (!isToolCallEventType("bash", event)) return undefined;

  const command = event.input.command;
  const normalized = normalizeCommand(command);

  if (approvedCommands.has(normalized)) return undefined;

  if (SAFE_PATTERNS.some((p) => p.test(normalized))) {
    return undefined;
  }

  // Dangerous: explicit approval, no timeout
  if (DANGEROUS_PATTERNS.some((p) => p.test(normalized))) {
    const choice = await selectWithNotification(
      ctx,
      `⚠️  Dangerous command:\n\n  ${command}\n\nApprove?`,
      ["Allow", "Allow + Remember", "Block"],
      "⚠️ pi: dangerous command",
      truncate(command, 200),
    );

    if (choice === "Allow + Remember") {
      approvedCommands.add(normalized);
      return undefined;
    }
    if (choice === "Allow") return undefined;

    ctx.abort();
    return { block: true, reason: "Dangerous command blocked by user" };
  }

  // Everything else: timed auto-approve
  const choice = await selectWithNotification(
    ctx,
    `🔍 bash: ${truncate(command, 120)}`,
    ["Allow", "Allow + Remember", "Block"],
    "🔍 pi: bash command",
    truncate(command, 200),
    { timeout: TIMED_APPROVE_MS },
  );

  if (choice === undefined) return undefined; // timeout → allow

  if (choice === "Allow + Remember") {
    approvedCommands.add(normalized);
    return undefined;
  }
  if (choice === "Allow") return undefined;

  ctx.abort();
  return { block: true, reason: "Bash command blocked by user" };
}

export async function handleUnknownTool(
  event: any,
  ctx: any,
): Promise<{ block: true; reason: string } | undefined> {
  const choice = await selectWithNotification(
    ctx,
    `🔧 ${event.toolName}: review call?`,
    ["Allow", "Block"],
    `🔧 pi: ${event.toolName}`,
    `Tool call requires review`,
    { timeout: TIMED_APPROVE_MS },
  );

  if (choice === undefined) return undefined;
  if (choice === "Allow") return undefined;

  ctx.abort();
  return { block: true, reason: `${event.toolName} blocked by user` };
}
