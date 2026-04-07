/**
 * Neovim diff review for file mutations (edit / write).
 *
 * Opens the proposed changes in a Neovim diff tab (embedded or
 * standalone) and lets the user Allow/Block. Supports `ai:` comments
 * for steering the agent from within the diff.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { spawnSync } from "node:child_process";
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
import { selectWithNotification } from "./notify.ts";

// ── Helpers ──────────────────────────────────────────────────────────

function cleanup(tmpDir: string, ...files: string[]) {
  for (const f of files) {
    try { unlinkSync(f); } catch {}
  }
  try { rmdirSync(tmpDir); } catch {}
}

function nvimRemoteSend(server: string, keys: string) {
  spawnSync("nvim", ["--server", server, "--remote-send", keys], {
    stdio: "ignore",
  });
}

/**
 * Apply all edits from the edits[] array to compute the proposed file
 * content. Returns null if any oldText is not found.
 */
function applyEdits(
  originalContent: string,
  edits: Array<{ oldText: string; newText: string }>,
): string | null {
  let content = originalContent;
  for (const edit of edits) {
    const idx = content.indexOf(edit.oldText);
    if (idx === -1) return null;
    content =
      content.slice(0, idx) +
      edit.newText +
      content.slice(idx + edit.oldText.length);
  }
  return content;
}

function hasAiComments(content: string): boolean {
  return /\bai:/.test(content);
}

/**
 * Handle user edits to the proposed file. If the user left `ai:`
 * comments the file is written as-is and the agent is steered to
 * follow the instructions.
 */
function handleUserEdits(
  pi: ExtensionAPI,
  afterContent: string,
  proposedContent: string,
  filePath: string,
  fileName: string,
  absolutePath: string,
): { block: true; reason: string } | undefined {
  if (afterContent === proposedContent) return undefined;

  writeFileSync(absolutePath, afterContent, "utf-8");

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

// ── Diff review (embedded Neovim) ────────────────────────────────────

async function reviewInEmbeddedNvim(
  pi: ExtensionAPI,
  ctx: any,
  nvimServer: string,
  filePath: string,
  fileName: string,
  absolutePath: string,
  proposedContent: string,
  tmpDir: string,
  currentFile: string,
  proposedFile: string,
): Promise<{ block: true; reason: string } | undefined> {
  const esc = (p: string) =>
    p.replace(/\\/g, "\\\\").replace(/ /g, "\\ ");

  nvimRemoteSend(nvimServer, [
    `<C-\\><C-n>`,
    `:tabnew ${esc(currentFile)}<CR>`,
    `:setlocal readonly nomodifiable bufhidden=wipe<CR>`,
    `:diffthis<CR>`,
    `:vsplit ${esc(proposedFile)}<CR>`,
    `:diffthis<CR>`,
    `:wincmd l<CR>`,
  ].join(""));

  const choice = await selectWithNotification(
    ctx,
    `${fileName} — diff opened in Neovim tab`,
    ["Allow", "Block"],
    `📝 pi: reviewing ${fileName}`,
    `Diff opened in Neovim — click to respond`,
  );

  nvimRemoteSend(
    nvimServer,
    `<C-\\><C-n>:bwipeout! ${esc(currentFile)}<CR>:bwipeout! ${esc(proposedFile)}<CR>`,
  );

  if (choice === "Block" || choice === undefined) {
    cleanup(tmpDir, currentFile, proposedFile);
    ctx.abort();
    return { block: true, reason: "Blocked by user after reviewing diff" };
  }

  let afterContent = proposedContent;
  try { afterContent = readFileSync(proposedFile, "utf-8"); } catch {}
  cleanup(tmpDir, currentFile, proposedFile);

  return handleUserEdits(pi, afterContent, proposedContent, filePath, fileName, absolutePath);
}

// ── Diff review (standalone Neovim) ──────────────────────────────────

async function reviewInStandaloneNvim(
  pi: ExtensionAPI,
  ctx: any,
  filePath: string,
  fileName: string,
  absolutePath: string,
  proposedContent: string,
  tmpDir: string,
  currentFile: string,
  proposedFile: string,
): Promise<{ block: true; reason: string } | undefined> {
  spawnSync(
    "nvim",
    [
      "-d", currentFile, proposedFile,
      "-c", `autocmd BufEnter ${currentFile.replace(/'/g, "''")} setlocal readonly nomodifiable`,
      "-c", "wincmd l",
      "-c", "autocmd QuitPre * qall",
    ],
    { stdio: "inherit", env: { ...process.env } },
  );

  let afterContent = proposedContent;
  try { afterContent = readFileSync(proposedFile, "utf-8"); } catch {}
  cleanup(tmpDir, currentFile, proposedFile);

  const editResult = handleUserEdits(pi, afterContent, proposedContent, filePath, fileName, absolutePath);
  if (editResult) return editResult;

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

// ── Public handler ───────────────────────────────────────────────────

export async function handleFileMutation(
  pi: ExtensionAPI,
  event: any,
  ctx: any,
): Promise<{ block: true; reason: string } | undefined> {
  let filePath: string;
  let originalContent = "";
  let proposedContent: string;

  if (isToolCallEventType("edit", event)) {
    filePath = event.input.path;
    try {
      const abs = resolve(ctx.cwd, filePath);
      if (existsSync(abs)) originalContent = readFileSync(abs, "utf-8");
    } catch {}
    const result = applyEdits(originalContent, event.input.edits);
    if (result === null) return undefined;
    proposedContent = result;
  } else if (isToolCallEventType("write", event)) {
    filePath = event.input.path;
    try {
      const abs = resolve(ctx.cwd, filePath);
      if (existsSync(abs)) originalContent = readFileSync(abs, "utf-8");
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
    return reviewInEmbeddedNvim(
      pi, ctx, nvimServer, filePath, fileName, absolutePath,
      proposedContent, tmpDir, currentFile, proposedFile,
    );
  } else {
    return reviewInStandaloneNvim(
      pi, ctx, filePath, fileName, absolutePath,
      proposedContent, tmpDir, currentFile, proposedFile,
    );
  }
}
