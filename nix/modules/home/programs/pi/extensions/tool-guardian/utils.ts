import type { ToolCallEventResult } from "@mariozechner/pi-coding-agent";

// ── Review actions ───────────────────────────────────────────────────

export enum ReviewAction {
  Allow = "Allow",
  AllowRemember = "Allow + Remember",
  Block = "Block",
}

/** Actions that should focus the terminal when chosen from a notification. */
export const FOCUS_ACTIONS = new Set<string>([ReviewAction.Block]);

// ── Guardian mode ────────────────────────────────────────────────────

export enum GuardMode {
  Guarded = "guarded",
  Yolo = "yolo",
}

// ── Shared types ─────────────────────────────────────────────────────

/** A tool call that was blocked by the guardian. */
export type BlockResult = ToolCallEventResult & { block: true; reason: string };

// ── Auto-allowed read-only tools ─────────────────────────────────────

export const READ_ONLY_TOOLS = new Set(["read", "ls", "find", "grep"]);

// ── Helpers ──────────────────────────────────────────────────────────

/** Truncate a string for display, adding an ellipsis if needed. */
export function truncate(s: string, max: number): string {
  if (s.length <= max) return s;
  return s.slice(0, max - 1) + "…";
}
