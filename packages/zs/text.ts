export function clean(value: unknown): string {
  return String(value).replace(/[\p{C}\p{Zl}\p{Zp}]/gu, " ");
}

export function object(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
export function json(text: string | null): unknown {
  try {
    return text === null ? null : JSON.parse(text);
  } catch {
    return null;
  }
}
export function compare(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}
