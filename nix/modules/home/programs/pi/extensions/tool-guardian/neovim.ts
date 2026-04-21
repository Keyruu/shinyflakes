/**
 * Neovim diff review for file mutations (edit / write).
 *
 * Uses the pi-guardian.nvim lua plugin to open a diff tab:
 *   Left pane:  scratch buffer with ORIGINAL content (readonly)
 *   Right pane: the ACTUAL file with PROPOSED changes (full LSP)
 *
 * Keybinds in the diff tab (set by the lua plugin):
 *   ga — Accept (writes file, closes diff)
 *   gx — Reject (restores original, closes diff)
 *   g+ — Expand diff context
 *   g- — Shrink diff context
 *
 * The keybinds race against the TUI select dialog and desktop
 * notification — whichever the user interacts with first wins.
 *
 * Supports `ai:` comments for steering the agent from within the diff.
 * On accept, `ai:` lines are stripped from the file and instructions
 * are delivered via a steer (user-role) message — no re-read needed
 * unless the user made manual edits beyond the ai: comments.
 */

import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmdirSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { selectWithNotification } from "./notify.ts";
import {
  luaStr,
  nvimRemoteSend,
  type ResponseData,
  uniqueId,
  watchForResponse,
} from "./nvim-ipc.ts";
import { type AcceptedResult, type MutationResult, ReviewAction } from "./utils.ts";

export type { ResponseData };

// ── Helpers ──────────────────────────────────────────────────────────

function accepted(fileName: string): AcceptedResult {
  return { accepted: true, message: `Applied changes to ${fileName}.` };
}

/** Extract `ai:` comment lines with their line numbers. */
function extractAiComments(content: string): string[] {
  const comments: string[] = [];
  const lines = content.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const match = lines[i]?.match(/\bai:\s*(.+)/);
    if (match?.[1]) {
      comments.push(`L${i + 1}: ${match[1].trim()}`);
    }
  }
  return comments;
}

/** Remove lines containing `ai:` comments, preserving other content. */
function stripAiComments(content: string): string {
  const lines = content.split("\n");
  const stripped = lines.filter((line) => !/\bai:\s*/.test(line));
  // Preserve trailing newline if original had one
  if (content.endsWith("\n") && !stripped.join("\n").endsWith("\n")) {
    return stripped.join("\n") + "\n";
  }
  return stripped.join("\n");
}

/** Compute a unified diff by shelling out to `diff -u`. */
function computeUserDiff(proposed: string, final: string): string {
  if (proposed === final) return "";

  const dir = mkdtempSync(join(tmpdir(), "pi-guardian-diff-"));
  const fileA = join(dir, "proposed");
  const fileB = join(dir, "final");
  writeFileSync(fileA, proposed, "utf-8");
  writeFileSync(fileB, final, "utf-8");

  const result = spawnSync(
    "diff",
    ["-u", "--minimal", "-L", "proposed", "-L", "edited", fileA, fileB],
    {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
    },
  );

  try {
    unlinkSync(fileA);
  } catch {}
  try {
    unlinkSync(fileB);
  } catch {}
  try {
    rmdirSync(dir);
  } catch {}

  return (result.stdout ?? "").trim();
}

const MAX_DIFF_LEN = 2000;
const MAX_DIFF_LINES = 60;

/** Truncate a diff to keep the message reasonable. */
function truncateDiff(diff: string): string {
  const lines = diff.split("\n");
  if (lines.length > MAX_DIFF_LINES) {
    return `${lines.slice(0, MAX_DIFF_LINES).join("\n")}\n... (${lines.length - MAX_DIFF_LINES} more lines)`;
  }
  if (diff.length > MAX_DIFF_LEN) {
    return `${diff.slice(0, MAX_DIFF_LEN)}\n... (truncated)`;
  }
  return diff;
}

/**
 * Process user edits from diff review:
 * 1. Extract ai: instructions from the edited content
 * 2. Strip ai: comment lines and write clean version to disk
 * 3. Send steer (user-role) message with instructions and/or diff
 * 4. Return an accepted result
 *
 * Steer messages have `role: "user"` so models treat them as
 * real instructions — much stronger than tool-result text.
 *
 * If the file only had ai: comments (no other edits), the model
 * does NOT need to re-read — instructions are in the steer message
 * and the file on disk is already clean.
 */
function processUserEdits(
  pi: ExtensionAPI,
  afterContent: string,
  proposedContent: string,
  filePath: string,
  fileName: string,
  absolutePath: string,
): AcceptedResult | undefined {
  const aiComments = extractAiComments(afterContent);
  const cleanContent = stripAiComments(afterContent);
  const hasRealEdits = cleanContent !== proposedContent;
  const hasInstructions = aiComments.length > 0;

  if (!hasRealEdits && !hasInstructions) return undefined;

  // Write the clean (ai:-stripped) version to disk
  writeFileSync(absolutePath, cleanContent, "utf-8");

  // Build steer message
  const steerParts: string[] = [];

  if (hasRealEdits) {
    steerParts.push(`I reviewed your changes to \`${filePath}\` and made adjustments.`);
    const diff = computeUserDiff(proposedContent, cleanContent);
    if (diff) {
      steerParts.push("");
      steerParts.push("Here's what I changed (- your version, + my version):");
      steerParts.push("```");
      steerParts.push(truncateDiff(diff));
      steerParts.push("```");
    }
    steerParts.push("");
    steerParts.push("Re-read the file before making further edits — the version on disk has my changes.");
  }

  if (hasInstructions) {
    if (!hasRealEdits) {
      steerParts.push(`I reviewed your changes to \`${filePath}\`.`);
    }
    steerParts.push("");
    steerParts.push("I have these instructions for you:");
    for (const c of aiComments) {
      steerParts.push(`- ${c}`);
    }
    steerParts.push("");
    steerParts.push("Follow every instruction above.");
  }

  pi.sendUserMessage(steerParts.join("\n"), { deliverAs: "steer" });

  // Build concise tool result
  const resultParts: string[] = [`Applied changes to ${fileName}.`];
  if (hasInstructions) resultParts.push("User instructions delivered separately.");
  if (hasRealEdits) resultParts.push("File on disk has user edits — re-read before further changes.");

  return { accepted: true, message: resultParts.join(" ") };
}

// ── Review context ───────────────────────────────────────────────────

interface ReviewContext {
  pi: ExtensionAPI;
  ctx: ExtensionContext;
  filePath: string;
  fileName: string;
  absolutePath: string;
  originalContent: string;
  proposedContent: string;
  reason?: string;
}

// ── Diff review (embedded Neovim) ────────────────────────────────────

async function reviewInEmbeddedNvim(
  rc: ReviewContext,
  nvimServer: string,
): Promise<MutationResult | undefined> {
  const { pi, ctx, filePath, fileName, absolutePath, originalContent, proposedContent, reason } =
    rc;

  const id = uniqueId();
  const payloadFile = join(tmpdir(), `pi-guardian-payload-${id}.json`);
  const responseFile = join(tmpdir(), `pi-guardian-response-${id}.json`);

  writeFileSync(
    payloadFile,
    JSON.stringify({
      path: absolutePath,
      original: originalContent,
      proposed: proposedContent,
      reason: reason || null,
      response_file: responseFile,
    }),
    "utf-8",
  );

  const { promise: nvimResponse, cancel: cancelWatch } = watchForResponse(responseFile);

  nvimRemoteSend(
    nvimServer,
    `<C-\\><C-n>:lua require('pi-guardian').review_from_file('${luaStr(payloadFile)}')<CR>`,
  );

  const externalAbort = new AbortController();

  type RaceResult =
    | { source: "tui"; choice: string | undefined }
    | { source: "nvim"; data: ResponseData };

  const reasonSuffix = reason ? `\n  Why: ${reason}` : "";
  const tuiPromise: Promise<RaceResult> = selectWithNotification(
    ctx,
    `${fileName} — diff in Neovim  [ga = accept, gx = reject]${reasonSuffix}`,
    [ReviewAction.Allow, ReviewAction.Block],
    `📝 pi: reviewing ${fileName}`,
    `${filePath} — diff opened in Neovim`,
    { signal: externalAbort.signal },
  ).then((choice) => ({ source: "tui" as const, choice }));

  const nvimPromise: Promise<RaceResult> = nvimResponse.then((data) => ({
    source: "nvim" as const,
    data,
  }));

  const result = await Promise.race([tuiPromise, nvimPromise]);
  cancelWatch();

  if (result.source === "nvim") {
    externalAbort.abort();

    if (result.data.decision === "block") {
      ctx.abort();
      return { block: true, reason: "Blocked by user after reviewing diff" };
    }

    const afterContent = result.data.content ?? proposedContent;
    return (
      processUserEdits(pi, afterContent, proposedContent, filePath, fileName, absolutePath) ??
      accepted(fileName)
    );
  }

  // TUI/notification won — dismiss nvim review (both Allow and Block)
  nvimRemoteSend(
    nvimServer,
    `<C-\\><C-n>:lua vim.schedule(function() ` +
      `local g = require('pi-guardian') ` +
      `if g._active_reject then g._active_reject() end ` +
      `end)<CR>`,
  );

  if (result.choice === ReviewAction.Block || result.choice === undefined) {
    ctx.abort();
    return { block: true, reason: "Blocked by user after reviewing diff" };
  }

  // TUI said Allow — nvim didn't write the file, do it here
  writeFileSync(absolutePath, proposedContent, "utf-8");
  return accepted(fileName);
}

// ── Diff review (standalone Neovim) ──────────────────────────────────

async function reviewInStandaloneNvim(rc: ReviewContext): Promise<MutationResult | undefined> {
  const { pi, ctx, filePath, fileName, absolutePath, originalContent, proposedContent, reason } =
    rc;
  const tmpDir = mkdtempSync(join(tmpdir(), "pi-guardian-"));
  const currentFile = join(tmpDir, `current_${basename(filePath)}`);
  const proposedFile = join(tmpDir, `proposed_${basename(filePath)}`);
  writeFileSync(currentFile, originalContent, "utf-8");
  writeFileSync(proposedFile, proposedContent, "utf-8");

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
    { stdio: "inherit", env: { ...process.env } },
  );

  let afterContent = proposedContent;
  try {
    afterContent = readFileSync(proposedFile, "utf-8");
  } catch {}

  try {
    unlinkSync(currentFile);
  } catch {}
  try {
    unlinkSync(proposedFile);
  } catch {}
  try {
    rmdirSync(tmpDir);
  } catch {}

  // Write ai:-stripped version to disk before TUI select so the file
  // reflects user edits minus ai: comments. If blocked, we restore
  // originalContent below so this write doesn't matter.
  if (afterContent !== proposedContent) {
    const cleanContent = stripAiComments(afterContent);
    if (cleanContent !== proposedContent) {
      writeFileSync(absolutePath, cleanContent, "utf-8");
    }
  }

  const reasonSuffix = reason ? `\n  Why: ${reason}` : "";
  const choice = await selectWithNotification(
    ctx,
    `${fileName}${reasonSuffix}`,
    [ReviewAction.Allow, ReviewAction.Block],
    `📝 pi: reviewing ${fileName}`,
    `${filePath} — diff review complete`,
  );

  if (choice === ReviewAction.Block || choice === undefined) {
    // Restore original — file may have user-edited content on disk
    writeFileSync(absolutePath, originalContent, "utf-8");
    ctx.abort();
    return { block: true, reason: "Blocked by user after reviewing diff" };
  }

  // Allowed — process user edits (strips ai: comments, writes clean version, sends steer)
  return (
    processUserEdits(pi, afterContent, proposedContent, filePath, fileName, absolutePath) ??
    accepted(fileName)
  );
}

// ── Review queue ────────────────────────────────────────────────────

let reviewQueue: Promise<unknown> = Promise.resolve();

// ── Public API ───────────────────────────────────────────────────────

/**
 * Show a diff review for a file mutation. Serialized through a queue
 * so only one review is active at a time.
 *
 * Callers provide the original and proposed content — this module
 * does not compute edits itself. The native tool has already written
 * the file to disk; on reject the caller is responsible for restoring.
 */
export function reviewFileDiff(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  opts: {
    filePath: string;
    absolutePath: string;
    originalContent: string;
    proposedContent: string;
    reason?: string;
  },
): Promise<MutationResult | undefined> {
  const result = new Promise<MutationResult | undefined>((resolve) => {
    reviewQueue = reviewQueue.then(async () => {
      const rc: ReviewContext = {
        pi,
        ctx,
        filePath: opts.filePath,
        fileName: basename(opts.filePath),
        absolutePath: opts.absolutePath,
        originalContent: opts.originalContent,
        proposedContent: opts.proposedContent,
        reason: opts.reason,
      };

      const nvimServer = process.env.NVIM;
      if (nvimServer) {
        resolve(await reviewInEmbeddedNvim(rc, nvimServer));
      } else {
        resolve(await reviewInStandaloneNvim(rc));
      }
    });
  });
  return result;
}