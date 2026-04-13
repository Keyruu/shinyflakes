import type { ToolCallEventResult } from "@mariozechner/pi-coding-agent";

// ── Review actions ───────────────────────────────────────────────────

export const ReviewAction = {
  Allow: "Allow",
  AllowRemember: "Allow + Remember",
  Block: "Block",
} as const;
export type ReviewAction = (typeof ReviewAction)[keyof typeof ReviewAction];

/** Actions that should focus the terminal when chosen from a notification. */
export const FOCUS_ACTIONS = new Set<string>([ReviewAction.Block]);

// ── Guardian mode ────────────────────────────────────────────────────

export const GuardMode = {
  Guarded: "guarded",
  Yolo: "yolo",
} as const;
export type GuardMode = (typeof GuardMode)[keyof typeof GuardMode];

// ── Shared types ─────────────────────────────────────────────────────

/** A tool call that was blocked by the guardian. */
export type BlockResult = ToolCallEventResult & { block: true; reason: string };

/** The diff review accepted and the file is already written to disk. */
export type AcceptedResult = { accepted: true; message: string };

/** Possible outcomes from a file mutation review. */
export type MutationResult = BlockResult | AcceptedResult;

// ── Auto-allowed read-only tools ─────────────────────────────────────

export const READ_ONLY_TOOLS = new Set(["read", "ls", "find", "grep"]);

// ── Blocked file paths ───────────────────────────────────────────────

/** Patterns for files the agent must never access. */
const BLOCKED_PATH_PATTERNS: RegExp[] = [
  // SOPS / secrets
  /^\/run\/secrets\b/,
  /secrets\.ya?ml$/,
  /\.sops\.ya?ml$/,
  /sops[\w-]*\.age/i,

  // Environment files with secrets (but not .example/.sample templates)
  /\.env$/,
  /\.env\.(?!example|sample|template)[\w.]+$/,

  // SSH
  /\.ssh\//,
  /id_(rsa|ed25519|ecdsa|dsa)(\.pub)?$/,
  /authorized_keys$/,
  /known_hosts$/,

  // GPG / age keys
  /\.gnupg\//,
  /\.age$/,

  // Token / credential files
  /\.netrc$/,
  /\.git-credentials$/,
  /\.npmrc$/,
  /\.docker\/config\.json$/,
];

/**
 * Check if a file path matches any blocked pattern.
 * Returns the block reason or undefined if allowed.
 */
export function isBlockedPath(filePath: string): string | undefined {
  for (const pattern of BLOCKED_PATH_PATTERNS) {
    if (pattern.test(filePath)) {
      return `Access to ${filePath} is blocked (matches secret/sensitive file pattern)`;
    }
  }
  return undefined;
}

// ── Helpers ──────────────────────────────────────────────────────────

/** Truncate a string for display, adding an ellipsis if needed. */
export function truncate(s: string, max: number): string {
  if (s.length <= max) return s;
  return `${s.slice(0, max - 1)}…`;
}
