/**
 * Bash command review with tiered approval.
 *
 *   - Safe patterns → auto-allow
 *   - Dangerous patterns → explicit approval (no timeout)
 *   - Everything else → timed auto-approve (3s countdown)
 *
 * Remembers approved commands within a session.
 *
 * When $NVIM is set, a floating modal in Neovim races against the
 * TUI select + desktop notification — whichever wins resolves the review.
 */

import type { ExtensionContext, ToolCallEvent } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { selectWithNotification } from "./notify.ts";
import { type ResponseData, requestNvimApproval } from "./nvim-ipc.ts";
import { DANGEROUS_PATTERNS, SAFE_PATTERNS } from "./patterns.ts";
import { type BlockResult, isBlockedPath, ReviewAction, truncate } from "./utils.ts";

const TIMED_APPROVE_MS = 5000;

function normalizeCommand(cmd: string): string {
  return cmd.replace(/\s+/g, " ").trim();
}

/** Map a nvim modal decision string to the equivalent ReviewAction. */
function nvimDecisionToChoice(decision: string): string | undefined {
  switch (decision) {
    case "allow":
      return ReviewAction.Allow;
    case "allow_remember":
      return ReviewAction.AllowRemember;
    case "block":
      return ReviewAction.Block;
    default:
      return undefined;
  }
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

// ── Three-way race: TUI + notification + nvim modal ──────────────────

type RaceResult =
  | { source: "tui"; choice: string | undefined }
  | { source: "nvim"; data: ResponseData };

interface RaceOptions {
  ctx: ExtensionContext;
  tuiTitle: string;
  options: string[];
  notifTitle: string;
  notifBody: string;
  timeout?: number;
}

/**
 * Race a TUI select + desktop notification against a Neovim floating
 * modal. Falls back to just TUI + notification when $NVIM is not set.
 */
async function raceApproval(opts: RaceOptions): Promise<string | undefined> {
  const { ctx, tuiTitle, options, notifTitle, notifBody, timeout } = opts;
  const nvimServer = process.env.NVIM;

  if (!nvimServer) {
    return selectWithNotification(ctx, tuiTitle, options, notifTitle, notifBody, { timeout });
  }

  const toolName = notifTitle.replace(/^[^\w]*/, "").replace(/^pi:\s*/, "");
  const nvim = requestNvimApproval(nvimServer, {
    tool_name: toolName,
    display: tuiTitle,
    dangerous: !timeout,
    response_file: "",
  });

  const externalAbort = new AbortController();

  const tuiPromise: Promise<RaceResult> = selectWithNotification(
    ctx,
    tuiTitle,
    options,
    notifTitle,
    notifBody,
    { timeout, signal: externalAbort.signal },
  ).then((choice) => ({ source: "tui" as const, choice }));

  const nvimPromise: Promise<RaceResult> = nvim.promise.then((data) => ({
    source: "nvim" as const,
    data,
  }));

  const result = await Promise.race([tuiPromise, nvimPromise]);

  if (result.source === "nvim") {
    externalAbort.abort();
    return nvimDecisionToChoice(result.data.decision);
  }

  // TUI won — dismiss the nvim modal
  nvim.cancel();
  return result.choice;
}

// ── Public handlers ──────────────────────────────────────────────────

export async function handleBash(
  event: ToolCallEvent,
  ctx: ExtensionContext,
  approvedCommands: Set<string>,
): Promise<BlockResult | undefined> {
  if (!isToolCallEventType("bash", event)) return undefined;

  const command = event.input.command;
  const normalized = normalizeCommand(command);

  const blockedReason = isBlockedPath(command);
  if (blockedReason) return { block: true, reason: blockedReason };

  if (approvedCommands.has(normalized)) return undefined;

  if (SAFE_PATTERNS.some((p) => p.test(normalized))) {
    return undefined;
  }

  // Dangerous: explicit approval, no timeout
  if (DANGEROUS_PATTERNS.some((p) => p.test(normalized))) {
    const choice = await raceApproval({
      ctx,
      tuiTitle: `⚠️  Dangerous command:\n\n  ${command}\n\nApprove?`,
      options: [ReviewAction.Allow, ReviewAction.AllowRemember, ReviewAction.Block],
      notifTitle: "⚠️ pi: dangerous command",
      notifBody: truncate(command, 200),
    });

    return resolveChoice(
      choice,
      ctx,
      normalized,
      approvedCommands,
      "Dangerous command blocked by user",
    );
  }

  // Everything else: timed auto-approve
  const choice = await raceApproval({
    ctx,
    tuiTitle: `🔍 bash: ${truncate(command, 120)}`,
    options: [ReviewAction.Allow, ReviewAction.AllowRemember, ReviewAction.Block],
    notifTitle: "🔍 pi: bash command",
    notifBody: truncate(command, 200),
    timeout: TIMED_APPROVE_MS,
  });

  return resolveChoice(choice, ctx, normalized, approvedCommands, "Bash command blocked by user");
}

export async function handleUnknownTool(
  event: ToolCallEvent,
  ctx: ExtensionContext,
  approvedTools: Set<string>,
): Promise<BlockResult | undefined> {
  if (approvedTools.has(event.toolName)) return undefined;

  const choice = await raceApproval({
    ctx,
    tuiTitle: `🔧 ${event.toolName}: review call?`,
    options: [ReviewAction.Allow, ReviewAction.AllowRemember, ReviewAction.Block],
    notifTitle: `🔧 pi: ${event.toolName}`,
    notifBody: "Tool call requires review",
    timeout: TIMED_APPROVE_MS,
  });

  return resolveChoice(
    choice,
    ctx,
    event.toolName,
    approvedTools,
    `${event.toolName} blocked by user`,
  );
}
