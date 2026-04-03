/**
 * Neovim Review Extension
 *
 * Intercepts `edit` and `write` tool calls BEFORE they execute.
 * If running inside Neovim ($NVIM is set), opens the diff in a new
 * tab in the parent Neovim session. Otherwise falls back to spawning
 * a standalone Neovim instance.
 *
 * Flow (inside Neovim terminal):
 *   1. AI proposes an edit/write
 *   2. Diff opens in a new tab in your Neovim session
 *   3. Pi shows Allow / Block immediately — review at your own pace
 *   4. If you edit the proposed file and save, your version is applied
 *
 * Flow (standalone):
 *   1. AI proposes an edit/write
 *   2. Neovim spawns with diff mode
 *   3. After quitting, choose Allow or Block
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync, unlinkSync, readFileSync, existsSync, rmdirSync } from "node:fs";
import { resolve, basename, join } from "node:path";
import { tmpdir } from "node:os";

function computeProposed(originalContent: string, oldText: string, newText: string): string | null {
  const idx = originalContent.indexOf(oldText);
  if (idx === -1) return null;
  return originalContent.slice(0, idx) + newText + originalContent.slice(idx + oldText.length);
}

function nvimRemoteSend(server: string, keys: string) {
  spawnSync("nvim", ["--server", server, "--remote-send", keys], {
    stdio: "ignore",
  });
}

export default function (pi: ExtensionAPI) {
  let enabled = true;

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Neovim review extension loaded", "info");
  });

  pi.registerCommand("neovim-review", {
    description: "Toggle neovim diff review for edit/write tool calls",
    handler: async (_args, ctx) => {
      enabled = !enabled;
      ctx.ui.notify(`Neovim review ${enabled ? "enabled" : "disabled"}`, "info");
    },
  });

  pi.on("tool_call", async (event, ctx) => {
    if (!enabled) return undefined;
    if (event.toolName !== "edit" && event.toolName !== "write") return undefined;
    if (!ctx.hasUI) return undefined;

    let filePath: string;
    let originalContent = "";
    let proposedContent: string;

    if (isToolCallEventType("edit", event)) {
      filePath = event.input.path;
      const absolutePath = resolve(ctx.cwd, filePath);

      try {
        if (existsSync(absolutePath)) {
          originalContent = readFileSync(absolutePath, "utf-8");
        }
      } catch {}

      const result = computeProposed(originalContent, event.input.oldText, event.input.newText);
      if (result === null) {
        return undefined;
      }
      proposedContent = result;

    } else if (isToolCallEventType("write", event)) {
      filePath = event.input.path;
      const absolutePath = resolve(ctx.cwd, filePath);

      try {
        if (existsSync(absolutePath)) {
          originalContent = readFileSync(absolutePath, "utf-8");
        }
      } catch {}

      proposedContent = event.input.content;
    } else {
      return undefined;
    }

    const fileName = basename(filePath);
    const absolutePath = resolve(ctx.cwd, filePath);

    // Write both versions to temp files for diff viewing
    const tmpDir = mkdtempSync(join(tmpdir(), "pi-review-"));
    const currentFile = join(tmpDir, `current_${fileName}`);
    const proposedFile = join(tmpDir, `proposed_${fileName}`);
    writeFileSync(currentFile, originalContent, "utf-8");
    writeFileSync(proposedFile, proposedContent, "utf-8");

    const nvimServer = process.env.NVIM;

    if (nvimServer) {
      // ── Running inside Neovim: open diff in a new tab ──
      // Escape any special characters for Neovim command-line
      const escPath = (p: string) => p.replace(/\\/g, "\\\\").replace(/ /g, "\\ ");

      const cmd = [
        `<C-\\><C-n>`,                              // ensure normal mode
        `:tabnew ${escPath(currentFile)}<CR>`,       // open current in new tab
        `:setlocal readonly nomodifiable bufhidden=wipe<CR>`,
        `:diffthis<CR>`,                             // diff left side
        `:vsplit ${escPath(proposedFile)}<CR>`,      // open proposed on right
        `:diffthis<CR>`,                             // diff right side
        `:wincmd l<CR>`,                             // focus proposed pane
      ].join("");

      nvimRemoteSend(nvimServer, cmd);

      // Show Allow/Block immediately — user reviews in Neovim at their pace
      const choice = await ctx.ui.select(
        `${fileName} — diff opened in Neovim tab`,
        ["Allow", "Block"]
      );

      // Wipe the temp buffers in Neovim
      const escFile = (p: string) => p.replace(/\\/g, "\\\\").replace(/ /g, "\\ ");
      nvimRemoteSend(nvimServer, `<C-\\><C-n>:bwipeout! ${escFile(currentFile)}<CR>:bwipeout! ${escFile(proposedFile)}<CR>`);

      if (choice === "Block" || choice === undefined) {
        // Clean up temp files
        try { unlinkSync(currentFile); } catch {}
        try { unlinkSync(proposedFile); } catch {}
        try { rmdirSync(tmpDir); } catch {}
        ctx.abort();
        return { block: true, reason: "Blocked by user after reviewing diff" };
      }

      // Allow — but check if user edited the proposed file first
      let userEdited = false;
      try {
        const afterContent = readFileSync(proposedFile, "utf-8");
        if (afterContent !== proposedContent) {
          writeFileSync(absolutePath, afterContent, "utf-8");
          userEdited = true;
        }
      } catch {}

      // Clean up temp files
      try { unlinkSync(currentFile); } catch {}
      try { unlinkSync(proposedFile); } catch {}
      try { rmdirSync(tmpDir); } catch {}

      if (userEdited) {
        return { block: true, reason: `User edited ${fileName} directly. Re-read the file to see their changes before making further edits.` };
      }

      return undefined;

    } else {
      // ── Standalone: spawn Neovim with diff mode ──
      spawnSync("nvim", [
        "-d",
        currentFile,
        proposedFile,
        "-c", `autocmd BufEnter ${currentFile.replace(/'/g, "''")} setlocal readonly nomodifiable`,
        "-c", "wincmd l",
        "-c", "autocmd QuitPre * qall",
      ], {
        stdio: "inherit",
        env: { ...process.env },
      });

      // Check if user edited the proposed file
      let userEdited = false;
      try {
        const afterContent = readFileSync(proposedFile, "utf-8");
        if (afterContent !== proposedContent) {
          writeFileSync(absolutePath, afterContent, "utf-8");
          userEdited = true;
        }
      } catch {}

      // Clean up
      try { unlinkSync(currentFile); } catch {}
      try { unlinkSync(proposedFile); } catch {}
      try { rmdirSync(tmpDir); } catch {}

      if (userEdited) {
        return { block: true, reason: `User edited ${fileName} directly. Re-read the file to see their changes before making further edits.` };
      }

      // User didn't edit — ask whether to apply or block and steer
      const choice = await ctx.ui.select(
        `${fileName}`,
        ["Allow", "Block"]
      );

      if (choice === "Block" || choice === undefined) {
        ctx.abort();
        return { block: true, reason: "Blocked by user after reviewing diff" };
      }

      return undefined;
    }
  });
}
