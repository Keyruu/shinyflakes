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
import {
  type AcceptedResult,
  type BlockResult,
  type MutationResult,
  ReviewAction,
} from "./utils.ts";

export type { ResponseData };

// ── Helpers ──────────────────────────────────────────────────────────

function hasAiComments(content: string): boolean {
  return /\bai:/.test(content);
}

function accepted(fileName: string): AcceptedResult {
  return { accepted: true, message: `Applied changes to ${fileName}.` };
}

/**
 * Check if the user modified the proposed content or left `ai:` comments.
 * Returns a BlockResult if the AI needs to react, or undefined if unmodified.
 */
function checkUserEdits(
  pi: ExtensionAPI,
  afterContent: string,
  proposedContent: string,
  filePath: string,
  fileName: string,
): BlockResult | undefined {
  if (afterContent === proposedContent) return undefined;

  if (hasAiComments(afterContent)) {
    pi.sendUserMessage(
      `I edited \`${filePath}\` and left \`ai:\` comments with instructions. ` +
        `Re-read the file, follow every \`ai:\` instruction, remove the \`ai:\` comment lines, and apply the changes.`,
      { deliverAs: "steer" },
    );
    return {
      block: true,
      reason: `User left ai: comments on ${fileName}. Re-read the file, follow every ai: instruction, and remove the ai: comment lines.`,
    };
  }

  return {
    block: true,
    reason: `User adjusted the proposed edit for ${fileName} and saved it. The file on disk already contains their version. Re-read it before making further edits.`,
  };
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
      checkUserEdits(pi, afterContent, proposedContent, filePath, fileName) ?? accepted(fileName)
    );
  }

  // TUI/notification won — tell nvim to clean up
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

  if (afterContent !== proposedContent) {
    writeFileSync(absolutePath, afterContent, "utf-8");
    const editResult = checkUserEdits(pi, afterContent, proposedContent, filePath, fileName);
    if (editResult) return editResult;
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
    ctx.abort();
    return { block: true, reason: "Blocked by user after reviewing diff" };
  }

  writeFileSync(absolutePath, proposedContent, "utf-8");
  return accepted(fileName);
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
