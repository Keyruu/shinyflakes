/**
 * Neovim Cursor Fix - removes pi's fake cursor, letting neovim's cursor be the only one.
 *
 * Problem: In neovim's terminal, you see two cursors — pi's fake cursor
 * (reverse-video block) AND neovim's TermCursor overlay. The TermCursor
 * pulsates/blinks based on guicursor and is always visible.
 *
 * Fix: Strip pi's fake cursor from the editor render output. The CURSOR_MARKER
 * still positions the hardware cursor correctly, so neovim's TermCursor appears
 * at the right place. Neovim natively handles showing TermCursor in terminal
 * mode and TermCursorNC when unfocused.
 *
 * To hide the cursor when the terminal split is unfocused, add to your neovim config:
 *   highlight TermCursorNC NONE
 *
 * Usage: place in ~/.pi/agent/extensions/neovim-cursor-fix.ts
 */

import { CustomEditor, type ExtensionAPI} from "@mariozechner/pi-coding-agent";

const REVERSE_VIDEO_RE = /\x1b\[7m([\s\S]*?)\x1b\[(?:0|27)m/g;

class NoFakeCursorEditor extends CustomEditor {
	render(width: number): string[] {
		const lines = super.render(width);
		// Strip the reverse-video fake cursor, keep the underlying character.
		// CURSOR_MARKER is preserved so neovim's TermCursor lands in the right spot.
		return lines.map((line) => line.replace(REVERSE_VIDEO_RE, "$1"));
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setEditorComponent((tui, theme, keybindings) =>
			new NoFakeCursorEditor(tui, theme, keybindings)
		);
	});
}
