/**
 * Notify Done Extension
 *
 * Sends a desktop notification when pi finishes processing a prompt.
 * Uses notify-send or falls back to a TUI notification.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";

function sendDesktopNotification(title: string, message: string) {
  try {
    execSync(
      `notify-send "${title.replace(/"/g, '\\"')}" "${message.replace(/"/g, '\\"')}"`,
      { stdio: "ignore" }
    );
  } catch {
    // Desktop notification not available; TUI fallback handled by caller
  }
}

export default function (pi: ExtensionAPI) {
  let enabled = true;

  pi.registerCommand("notify-done", {
    description: "Toggle desktop notification when pi finishes",
    handler: async (_args, ctx) => {
      enabled = !enabled;
      ctx.ui.notify(`Done notification ${enabled ? "enabled" : "disabled"}`, "info");
    },
  });

  pi.on("agent_end", async (_event, ctx) => {
    if (!enabled) return;
    sendDesktopNotification("pi", "Agent finished processing");
    ctx.ui.notify("pi finished", "success");
  });
}
