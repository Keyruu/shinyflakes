/**
 * Review scope filtering for file mutations.
 *
 * Controls which files go through neovim diff review vs auto-allow.
 * Configured via environment variables:
 *
 *   GUARDIAN_REVIEW_INCLUDE            — comma-separated glob patterns to include
 *   GUARDIAN_REVIEW_EXCLUDE            — comma-separated glob patterns to exclude
 *   GUARDIAN_REVIEW_INCLUDE_EXTENSIONS — comma-separated extensions (e.g. .ts,.tsx)
 *   GUARDIAN_REVIEW_EXCLUDE_EXTENSIONS — comma-separated extensions (e.g. .lock,.snap)
 *
 * When include patterns/extensions are set, only matching files are reviewed.
 * Exclude patterns always take precedence over includes.
 * When no filters are set, all files are reviewed.
 */

import { basename, extname } from "node:path";

export interface ReviewScope {
  includePatterns: string[];
  excludePatterns: string[];
  includeExtensions: string[];
  excludeExtensions: string[];
}

function parseCsv(input?: string): string[] {
  if (!input) return [];
  return input
    .split(",")
    .map((v) => v.trim())
    .filter(Boolean);
}

function normalizeExtension(token: string): string | undefined {
  const trimmed = token.trim().toLowerCase();
  if (!trimmed) return undefined;
  return trimmed.startsWith(".") ? trimmed : `.${trimmed}`;
}

function escapeRegex(value: string): string {
  return value.replace(/[|\\{}()[\]^$+?.]/g, "\\$&");
}

function globToRegExp(pattern: string): RegExp {
  let regex = "^";
  for (let i = 0; i < pattern.length; i++) {
    const char = pattern[i] ?? "";
    if (char === "*") {
      if (pattern[i + 1] === "*") {
        regex += ".*";
        i++;
      } else {
        regex += "[^/]*";
      }
      continue;
    }
    if (char === "?") {
      regex += "[^/]";
      continue;
    }
    regex += escapeRegex(char);
  }
  regex += "$";
  return new RegExp(regex);
}

function normalizePattern(pattern: string): string {
  return pattern.replace(/\\/g, "/").replace(/^\.\//, "");
}

function normalizePath(path: string): string {
  return path.replace(/\\/g, "/");
}

function matchesPattern(path: string, pattern: string): boolean {
  const normalizedPattern = normalizePattern(pattern);
  if (!normalizedPattern) return false;
  const matcher = globToRegExp(normalizedPattern);
  const normalizedPath = normalizePath(path);

  if (normalizedPattern.includes("/")) {
    return matcher.test(normalizedPath);
  }
  return matcher.test(basename(normalizedPath)) || matcher.test(normalizedPath);
}

export function createReviewScope(env: NodeJS.ProcessEnv = process.env): ReviewScope {
  const includeExtensions = parseCsv(env.GUARDIAN_REVIEW_INCLUDE_EXTENSIONS)
    .map(normalizeExtension)
    .filter((ext): ext is string => Boolean(ext));
  const excludeExtensions = parseCsv(env.GUARDIAN_REVIEW_EXCLUDE_EXTENSIONS)
    .map(normalizeExtension)
    .filter((ext): ext is string => Boolean(ext));

  return {
    includePatterns: parseCsv(env.GUARDIAN_REVIEW_INCLUDE).map(normalizePattern),
    excludePatterns: parseCsv(env.GUARDIAN_REVIEW_EXCLUDE).map(normalizePattern),
    includeExtensions,
    excludeExtensions,
  };
}

export function isInReviewScope(path: string, scope: ReviewScope): boolean {
  const normalizedPath = normalizePath(path);
  const extension = extname(normalizedPath).toLowerCase();

  if (scope.includeExtensions.length > 0 && !scope.includeExtensions.includes(extension)) {
    return false;
  }
  if (scope.excludeExtensions.includes(extension)) {
    return false;
  }
  if (
    scope.includePatterns.length > 0 &&
    !scope.includePatterns.some((p) => matchesPattern(normalizedPath, p))
  ) {
    return false;
  }
  if (scope.excludePatterns.some((p) => matchesPattern(normalizedPath, p))) {
    return false;
  }
  return true;
}

/** Check if scope has any filters configured. */
export function hasFilters(scope: ReviewScope): boolean {
  return (
    scope.includePatterns.length > 0 ||
    scope.excludePatterns.length > 0 ||
    scope.includeExtensions.length > 0 ||
    scope.excludeExtensions.length > 0
  );
}
