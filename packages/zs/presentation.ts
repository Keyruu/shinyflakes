import { clean, object } from "./text.ts";
import { githubPreview, prBadge } from "./github.ts";
import type { Marker, Pane, Row } from "./main.ts";

export interface Attention {
  rank: number;
  icon: string;
  text: string;
  native: boolean;
  fallback?: string;
}

export function attention(
  pane: Partial<Pane>,
  marker?: Pick<Marker, "status">,
): Attention {
  const normalize = (value: unknown) => String(value).toLowerCase().replace(/[^a-z]/g, "");
  const native = object(pane.attention) ? pane.attention : {};
  const state = normalize(native.status ?? "idle");
  const muted = native.muted != null && native.muted !== false;
  const states: Record<string, [number, string, string]> = {
    needsyou: [6, "●", "needs you"],
    failed: [5, "✗", "failed"],
    done: [4, "✓", "unread result"],
    quiet: [3, "◌", "quiet"],
    newoutput: [2, "•", "new output"],
    working: [1, "◐", "working"],
    idle: [0, "○", "idle"],
  };
  let [rank, icon, text] = states[state] ?? [0, "?", "unknown"];
  if (native.seen === true && ["done", "failed", "quiet", "newoutput"].includes(state))
    [rank, icon, text] = [0, "○", `${state} · seen`];
  if (muted) {
    rank = 0;
    text += " · muted";
  }

  // Generic output/idle observations do not replace unreported Pi lifecycle.
  const records = Array.isArray(pane.program_status) ? pane.program_status : [];
  const explicit = normalize(native.source) === "programstatus" ||
    records.some((record) => object(record) && record.app === "pi");
  const fallback = marker && !explicit ? marker.status ?? "unknown" : undefined;
  if (fallback !== undefined && !muted) {
    const ranks: Record<string, number> = { review: 6, waiting: 6, question: 6, working: 1 };
    rank = Math.max(rank, ranks[fallback] ?? 0);
  }
  return { rank, icon, text, native: Object.keys(native).length > 0, fallback };
}

export function attentionText(activity: Attention, compact = false): string {
  const native = activity.native
    ? `${compact && activity.icon === "●" ? "!" : activity.icon} ${activity.text}${compact ? "" : " · Zellij"}`
    : "";
  if (activity.fallback !== undefined)
    return (native ? native + " | " : "") + `Pi ${clean(activity.fallback)} · seen unknown`;
  return native || "? status unavailable";
}

export function rowStatus(row: Row, compact = false): string {
  const status = row.activity
    ? attentionText(row.activity, compact)
    : row.status ?? (row.open === true ? "live" : row.open === false ? "closed" : "");
  if (!row.savedSession) return status;
  return row.open ? `${status} · ♻ resurrectable` : "♻ resurrectable";
}

export function rowLabel(row: Row): string {
  if (row.label !== undefined) return clean(row.label);
  if (!row.display) return clean(row.title ?? row.session ?? row.path ?? row.id);
  const { prefix, name, detail, context } = row.display;
  return clean(`${row.kind === "repo" ? "▾ " : prefix}${name}  ${rowStatus(row)}  · ${context ?? detail}`);
}

export function rowPreview(row: Row): string {
  if (row.preview !== undefined) return row.preview;
  if (!row.kind) return rowLabel(row);
  const data = { ...row, status: rowStatus(row) || undefined };
  const fields = ["kind", "path", "branch", "session", "savedSession", "tab", "pane", "open", "status"] as const;
  const sections = [fields.filter((field) => data[field] != null)
    .map((field) => clean(`${field}: ${data[field]}`)).join("\n")];
  if (row.sessions) sections.push("sessions: " + (row.sessions.map(clean).join(", ") || "none"));
  if (row.github) sections.push("\n" + githubPreview(row.github, row.pullRequests ?? []));
  return sections.join("\n");
}

export function dmenuLabel(row: Row): string {
  return rowLabel(row) + (row.pullRequests ?? []).map((pr) => ` [${prBadge(pr)}]`).join("");
}

export function renderRow(row: Row, color = !process.env.NO_COLOR): string {
  if (!row.display || !row.kind) return rowLabel(row);
  // Only our styles may emit escapes; names and status can contain untrusted terminal metadata.
  const style = (text: string, code: string) =>
    color ? `\x1b[${code}m${text}\x1b[0m` : text;
  const paint = (text: string, code: string) => style(clean(text), code);
  const { prefix, name, detail } = row.display;
  const rank = row.rank ?? 0;
  const icon = {
    repo: "",
    worktree: "⎇",
    directory: "▱",
    agent: "◆",
    workspace: "▤",
    session: "▤",
  }[row.kind];
  const nameStyle =
    (row.kind === "repo" ? "1;" : "") + (row.open ? "37" : "90");
  const statusStyle =
    rank >= 5
      ? "1;31"
      : rank === 4
        ? "1;32"
        : rank === 1
          ? "33"
          : rank > 0
            ? "36"
            : "2";
  const status = rowStatus(row, true);
  const badges = (row.pullRequests ?? [])
    .map((pr) => {
      const glyph =
        pr.state === "MERGED"
          ? ""
          : pr.state === "CLOSED"
            ? ""
            : pr.isDraft
              ? ""
              : "";
      return style(
        `${glyph} #${clean(pr.number)} `,
        pr.state === "MERGED"
          ? "35"
          : pr.state === "CLOSED"
            ? "31"
            : pr.isDraft
              ? "2"
              : "32",
      );
    })
    .join("");
  const state =
    !color && row.open !== undefined && row.kind !== "repo"
      ? ` [${row.open ? "open" : "closed"}]`
      : "";
  const activity =
    row.kind !== "repo" &&
    status &&
    !["closed", "live", "○ idle"].includes(status)
      ? "  " + paint(status, statusStyle)
      : "";
  const context =
    row.kind === "agent" || row.kind === "workspace"
      ? paint(`  · ${detail}`, "2")
      : "";
  return (
    paint(prefix, "2") +
    badges +
    paint(`${!badges && icon ? icon + " " : ""}${name}`, nameStyle) +
    state +
    activity +
    context
  );
}
