/**
 * /stage — inject the tmux pi-prompt staging file into pi's editor.
 *
 * Pairs with the copy-mode workflow defined in
 * nix/modules/home/shell/tmux/default.nix:
 *   A (copy-mode) opens $EDITOR on /tmp/tmux-pi-prompt-<sid>.txt
 *   X (copy-mode) clears the staging file
 *   /stage in pi injects the file's contents into the editor
 *
 * Going through the extension API instead of tmux paste-buffer avoids the
 * csi-u Ctrl+J re-encoding tmux applies to LF inside bracketed paste, and
 * keeps multi-line content as a single prompt instead of one-per-line.
 *
 * Subcommands:
 *   /stage          inject current staging contents into editor (and clear)
 *   /stage show     show staged contents without injecting
 *   /stage clear    discard staged contents
 *   /stage keep     inject but don't clear
 */

import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function stagePath(): string {
	const tmux = process.env.TMUX;
	const pane = process.env.TMUX_PANE;
	if (tmux && pane) {
		try {
			const sid = execFileSync("tmux", ["display", "-p", "-t", pane, "#{session_id}"], {
				encoding: "utf8",
			})
				.trim()
				.replace(/^\$/, "");
			if (sid) return `/tmp/tmux-pi-prompt-${sid}.txt`;
		} catch {
			// fall through to default
		}
	}
	return "/tmp/tmux-pi-prompt-default.txt";
}

function readStage(path: string): string {
	if (!existsSync(path)) return "";
	return readFileSync(path, "utf8");
}

export default function stageExtension(pi: ExtensionAPI) {
	pi.registerCommand("stage", {
		description: "Inject tmux pi-prompt staging file into editor",
		getArgumentCompletions: (prefix) => {
			const subs = ["show", "clear", "keep"];
			const filtered = subs.filter((s) => s.startsWith(prefix));
			return filtered.length > 0 ? filtered.map((s) => ({ value: s, label: s })) : null;
		},
		handler: async (args, ctx) => {
			const path = stagePath();
			const sub = args.trim();
			const content = readStage(path);

			if (sub === "show") {
				if (!content) {
					ctx.ui.notify(`stage empty (${path})`, "info");
				} else {
					ctx.ui.notify(`stage (${content.length} bytes):\n${content}`, "info");
				}
				return;
			}

			if (sub === "clear") {
				writeFileSync(path, "");
				ctx.ui.notify("stage cleared", "info");
				return;
			}

			if (sub !== "" && sub !== "keep") {
				ctx.ui.notify(`unknown /stage subcommand: ${sub}`, "warning");
				return;
			}

			if (!content) {
				ctx.ui.notify(`stage empty (${path})`, "warning");
				return;
			}

			// Strip a single trailing newline editors typically add — pi's editor
			// would otherwise show a dangling blank line. Internal newlines are
			// preserved as the prompt is multi-line.
			const stripped = content.replace(/\n$/, "");
			ctx.ui.pasteToEditor(stripped);

			if (sub !== "keep") {
				writeFileSync(path, "");
			}
			ctx.ui.notify(`stage: injected ${stripped.length} bytes`, "info");
		},
	});
}
