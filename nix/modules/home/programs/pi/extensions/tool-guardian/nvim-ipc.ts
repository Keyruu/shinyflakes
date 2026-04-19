/**
 * Neovim IPC — remote-send commands and file-based response watching.
 *
 * Communication with the pi-guardian.nvim plugin uses JSON files in /tmp:
 *   payload.json  → extension writes
 *   response.json ← plugin writes
 *
 * File watching detects when the plugin writes its response.
 */

import { spawnSync } from "node:child_process";
import { readFileSync, unlinkSync, watch, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join } from "node:path";

export interface ResponseData {
  decision: string;
  content?: string;
}

export interface ApprovalPayload {
  tool_name: string;
  display: string;
  dangerous: boolean;
  response_file: string;
}

/** Send keystrokes to a running Neovim instance via --remote-send. */
export function nvimRemoteSend(server: string, keys: string): void {
  spawnSync("nvim", ["--server", server, "--remote-send", keys], {
    stdio: "ignore",
  });
}

/** Escape a string for embedding in a Lua single-quoted string literal. */
export function luaStr(s: string): string {
  return s.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
}

/** Generate a unique ID for temporary file naming. */
export function uniqueId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

/**
 * Watch for a JSON response file to appear and contain valid data.
 *
 * Returns a promise that resolves when the file is written with valid
 * JSON, plus a cancel function to stop watching. Logs a warning on
 * JSON parse failure instead of silently swallowing the error.
 */
export function watchForResponse(responseFile: string): {
  promise: Promise<ResponseData>;
  cancel: () => void;
} {
  const dir = dirname(responseFile);
  const file = basename(responseFile);
  let watcher: ReturnType<typeof watch> | null = null;
  let cancelled = false;

  /** Read and resolve if the response file already has valid content. */
  function tryResolve(resolvePromise: (data: ResponseData) => void): boolean {
    try {
      const raw = readFileSync(responseFile, "utf-8").trim();
      if (raw) {
        const data = JSON.parse(raw) as ResponseData;
        cancelled = true;
        watcher?.close();
        try {
          unlinkSync(responseFile);
        } catch {}
        resolvePromise(data);
        return true;
      }
    } catch (err) {
      if (err instanceof SyntaxError) {
        console.error(`[guardian] malformed response JSON in ${responseFile}: ${err.message}`);
      }
    }
    return false;
  }

  const promise = new Promise<ResponseData>((resolvePromise) => {
    try {
      watcher = watch(dir, (_eventType, filename) => {
        if (cancelled || filename !== file) return;
        tryResolve(resolvePromise);
      });

      // Check for a response that arrived between watcher setup and
      // the first OS event — fs.watch only fires on *changes*, so a
      // write that lands right after our watch() call is missed silently.
      tryResolve(resolvePromise);
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

/**
 * Send a tool call approval request to an embedded Neovim instance.
 *
 * Opens a floating modal via the pi-guardian.nvim plugin. Returns a
 * promise that resolves when the user acts (ga/gx/gR) or is cancelled
 * externally. The `cancel` function dismisses the modal from the
 * extension side (e.g. when TUI wins the race).
 */
export function requestNvimApproval(
  nvimServer: string,
  payload: ApprovalPayload,
): { promise: Promise<ResponseData>; cancel: () => void } {
  const id = uniqueId();
  const payloadFile = join(tmpdir(), `pi-guardian-payload-${id}.json`);
  const responseFile = join(tmpdir(), `pi-guardian-response-${id}.json`);

  payload.response_file = responseFile;
  writeFileSync(payloadFile, JSON.stringify(payload), "utf-8");

  const { promise, cancel: cancelWatch } = watchForResponse(responseFile);

  nvimRemoteSend(
    nvimServer,
    `<C-\\><C-n>:lua require('pi-guardian').approve_from_file('${luaStr(payloadFile)}')<CR>`,
  );

  const cancel = () => {
    cancelWatch();
    nvimRemoteSend(
      nvimServer,
      `<C-\\><C-n>:lua vim.schedule(function() ` +
        `local g = require('pi-guardian') ` +
        `if g._active_modal_reject then g._active_modal_reject() end ` +
        `end)<CR>`,
    );
  };

  return { promise, cancel };
}
