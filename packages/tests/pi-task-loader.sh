#!/usr/bin/env bash
set -euo pipefail
source_root=$(realpath "$(dirname "$0")/../../modules/aspects/agents/pi")
pi=$(command -v pi)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/agent/extensions"
ln -s "$source_root/extensions/tool-guardian" "$tmp/agent/extensions/tool-guardian"
ln -s "$source_root/lib" "$tmp/agent/lib"
tee "$tmp/agent/probe.ts" >/dev/null <<'TS'
import { TaskReview } from "./extensions/tool-guardian/task-review.ts";
export default function (pi: any) {
  if (typeof TaskReview !== "function") throw new Error("TaskReview import failed");
  console.error("SHARED_TASK_STATE_IMPORT_OK");
  pi.on("session_start", (_event: unknown, ctx: any) => ctx.shutdown());
}
TS
# No prompt, persisted session, credentials, MCP, or active task hooks are involved.
(cd "$tmp" && env -u PI_TASK_ROOT -u PI_TASK_REVIEW_STATE HOME="$tmp" \
  PI_CODING_AGENT_DIR="$tmp/agent" PI_TELEMETRY=0 "$pi" --offline --mode rpc --no-session \
  --no-extensions --no-mcp --no-skills --no-prompt-templates --no-themes --no-context-files \
  --extension "$tmp/agent/probe.ts" </dev/null) >"$tmp/out" 2>"$tmp/err"
if ! grep -q '^SHARED_TASK_STATE_IMPORT_OK$' "$tmp/err"; then
  printf 'Pi failed to load the shared library through Home Manager symlinks:\n' >&2
  head -n 20 "$tmp/err" >&2
  exit 1
fi
printf 'pi-task extension loader fixture: OK\n'
