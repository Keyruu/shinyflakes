/**
 * Neovim diff review for file mutations (edit / write).
 *
 * Opens the proposed changes in a Neovim diff tab (embedded or
 * standalone) and lets the user Allow/Block. Supports `ai:` comments
 * for steering the agent from within the diff.
 *
 * In embedded mode, buffer-local keybinds are set on the proposed
 * (right) pane:
 *   ga — Allow (guardian-accept: saves edits, closes diff)
 *   gx — Block (guardian-reject: closes diff, rejects change)
 *
 * The keybinds race against the TUI select dialog and desktop
 * notification — whichever the user interacts with first wins.
 */

import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  rmdirSync,
  unlinkSync,
  watch,
  writeFileSync,
} from "node:fs";
import { basename, join, resolve } from "node:path";
import type { ExtensionAPI, ExtensionContext, ToolCallEvent } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { selectWithNotification } from "./notify.ts";
import { type BlockResult, ReviewAction } from "./utils.ts";

// ── Helpers ──────────────────────────────────────────────────────────

function cleanup(tmpDir: string, ...files: string[]) {
  for (const f of files) {
    try {
      unlinkSync(f);
    } catch {}
  }
  try {
    rmdirSync(tmpDir);
  } catch {}
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
    content = content.slice(0, idx) + edit.newText + content.slice(idx + edit.oldText.length);
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
): BlockResult | undefined {
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

// ── Decision file watcher ────────────────────────────────────────────

function watchForDecision(
  tmpDir: string,
  decisionFile: string,
): { promise: Promise<string>; cancel: () => void } {
  let watcher: ReturnType<typeof watch> | null = null;
  let cancelled = false;

  const promise = new Promise<string>((resolve) => {
    try {
      watcher = watch(tmpDir, (_eventType, filename) => {
        if (cancelled || filename !== "decision") return;
        try {
          const decision = readFileSync(decisionFile, "utf-8").trim();
          if (decision) {
            cancelled = true;
            watcher?.close();
            resolve(decision);
          }
        } catch {}
      });
    } catch {}
  });

  const cancel = () => {
    cancelled = true;
    try {
      watcher?.close();
    } catch {}
  };

  return { promise, cancel };
}

// ── Diff review (embedded Neovim) ────────────────────────────────────

async function reviewInEmbeddedNvim(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  nvimServer: string,
  filePath: string,
  fileName: string,
  absolutePath: string,
  proposedContent: string,
  tmpDir: string,
  currentFile: string,
  proposedFile: string,
): Promise<BlockResult | undefined> {
  const esc = (p: string) => p.replace(/\\/g, "\\\\").replace(/ /g, "\\ ");
  const luaStr = (s: string) => s.replace(/\\/g, "\\\\").replace(/'/g, "\\'");

  const decisionFile = join(tmpDir, "decision");

  // Lua keybind functions for allow/block
  // Wrap bwipeout in vim.schedule so highlight-undo callbacks
  // run before the buffer is destroyed (avoids "Invalid buffer id")
  const scheduleWipe = (bufs: string) => `vim.schedule(function() ${bufs} end)`;

  const luaAllowFn = [
    `vim.cmd('w')`,
    `vim.fn.writefile({'allow'},'${luaStr(decisionFile)}')`,
    scheduleWipe(
      `vim.cmd('noautocmd bwipeout! ${luaStr(currentFile)}') vim.cmd('noautocmd bwipeout!')`,
    ),
  ].join(" ");

  const luaBlockFn = [
    `vim.fn.writefile({'block'},'${luaStr(decisionFile)}')`,
    scheduleWipe(
      `vim.cmd('noautocmd bwipeout! ${luaStr(currentFile)}') vim.cmd('noautocmd bwipeout!')`,
    ),
  ].join(" ");

  nvimRemoteSend(
    nvimServer,
    [
      `<C-\\><C-n>`,
      `:tabnew ${esc(currentFile)}<CR>`,
      `:setlocal readonly nomodifiable bufhidden=wipe<CR>`,
      `:diffthis<CR>`,
      `:vsplit ${esc(proposedFile)}<CR>`,
      `:diffthis<CR>`,
      `:wincmd l<CR>`,
      // Buffer-local keybinds on the proposed (editable) pane
      `:lua vim.keymap.set('n','ga',function() ${luaAllowFn} end,{buffer=true,desc='Guardian: Allow'})<CR>`,
      `:lua vim.keymap.set('n','gx',function() ${luaBlockFn} end,{buffer=true,desc='Guardian: Block'})<CR>`,
    ].join(""),
  );

  // Watch for decision from Neovim keybind
  const { promise: nvimDecision, cancel: cancelWatch } = watchForDecision(tmpDir, decisionFile);

  // AbortController to cancel TUI select when Neovim keybind wins
  const externalAbort = new AbortController();

  type RaceResult =
    | { source: "tui"; choice: string | undefined }
    | { source: "nvim"; choice: string };

  const tuiPromise: Promise<RaceResult> = selectWithNotification(
    ctx,
    `${fileName} — diff in Neovim  [ga = allow, gx = block]`,
    [ReviewAction.Allow, ReviewAction.Block],
    `📝 pi: reviewing ${fileName}`,
    `${filePath} — diff opened in Neovim`,
    { signal: externalAbort.signal },
  ).then((choice) => ({ source: "tui" as const, choice }));

  const nvimPromise: Promise<RaceResult> = nvimDecision.then((decision) => ({
    source: "nvim" as const,
    choice: decision === "allow" ? ReviewAction.Allow : ReviewAction.Block,
  }));

  const result = await Promise.race([tuiPromise, nvimPromise]);

  // Cancel the loser
  cancelWatch();
  if (result.source === "nvim") {
    externalAbort.abort();
  } else {
    // TUI/notification won — clean up Neovim buffers from Node side
    nvimRemoteSend(
      nvimServer,
      `<C-\\><C-n>:lua vim.schedule(function() vim.cmd('noautocmd bwipeout! ${esc(currentFile)}') vim.cmd('noautocmd bwipeout! ${esc(proposedFile)}') end)<CR>`,
    );
  }

  if (result.choice === ReviewAction.Block || result.choice === undefined) {
    cleanup(tmpDir, currentFile, proposedFile, decisionFile);
    ctx.abort();
    return { block: true, reason: "Blocked by user after reviewing diff" };
  }

  let afterContent = proposedContent;
  try {
    afterContent = readFileSync(proposedFile, "utf-8");
  } catch {}
  cleanup(tmpDir, currentFile, proposedFile, decisionFile);

  return handleUserEdits(pi, afterContent, proposedContent, filePath, fileName, absolutePath);
}

// ── Diff review (standalone Neovim) ──────────────────────────────────

async function reviewInStandaloneNvim(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  filePath: string,
  fileName: string,
  absolutePath: string,
  proposedContent: string,
  tmpDir: string,
  currentFile: string,
  proposedFile: string,
): Promise<BlockResult | undefined> {
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
  cleanup(tmpDir, currentFile, proposedFile);

  const editResult = handleUserEdits(
    pi,
    afterContent,
    proposedContent,
    filePath,
    fileName,
    absolutePath,
  );
  if (editResult) return editResult;

  const choice = await selectWithNotification(
    ctx,
    `${fileName}`,
    [ReviewAction.Allow, ReviewAction.Block],
    `📝 pi: reviewing ${fileName}`,
    `${filePath} — diff review complete`,
  );

  if (choice === ReviewAction.Block || choice === undefined) {
    ctx.abort();
    return { block: true, reason: "Blocked by user after reviewing diff" };
  }

  return undefined;
}

// ── Review queue ────────────────────────────────────────────────────

/**
 * Serialize diff reviews so only one runs at a time.
 * Without this, rapid edit/write calls open multiple diff tabs
 * simultaneously, causing competing keybinds and buffer wipes.
 */
let reviewQueue: Promise<unknown> = Promise.resolve();

// ── Public handler ───────────────────────────────────────────────────

export function handleFileMutation(
  pi: ExtensionAPI,
  event: ToolCallEvent,
  ctx: ExtensionContext,
): Promise<BlockResult | undefined> {
  const result = new Promise<BlockResult | undefined>((resolve) => {
    reviewQueue = reviewQueue.then(async () => {
      resolve(await doHandleFileMutation(pi, event, ctx));
    });
  });
  return result;
}

async function doHandleFileMutation(
  pi: ExtensionAPI,
  event: ToolCallEvent,
  ctx: ExtensionContext,
): Promise<BlockResult | undefined> {
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

  // Create temp dir next to the actual file so LSP can find tsconfig/project config
  const fileDir = resolve(ctx.cwd, filePath, "..");
  const tmpDir = mkdtempSync(join(fileDir, ".pi-guardian-"));
  const currentFile = join(tmpDir, `current_${fileName}`);
  const proposedFile = join(tmpDir, `proposed_${fileName}`);
  writeFileSync(currentFile, originalContent, "utf-8");
  writeFileSync(proposedFile, proposedContent, "utf-8");

  const nvimServer = process.env.NVIM;

  if (nvimServer) {
    return reviewInEmbeddedNvim(
      pi,
      ctx,
      nvimServer,
      filePath,
      fileName,
      absolutePath,
      proposedContent,
      tmpDir,
      currentFile,
      proposedFile,
    );
  } else {
    return reviewInStandaloneNvim(
      pi,
      ctx,
      filePath,
      fileName,
      absolutePath,
      proposedContent,
      tmpDir,
      currentFile,
      proposedFile,
    );
  }
}
