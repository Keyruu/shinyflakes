# Task-attached agent review workflow

For implementation status and package paths, see [Pi task workflow redesign](pi-task-workflow-redesign.md).
The [simplification backlog](pi-workflow-simplification.md) records the current
direction. Source now delegates exited-session restoration to Zellij; automatic
missing-Pi and layout repair are retired. Earlier repair smoke results in the
rollout history describe the previous implementation, not the current contract.
Source changes do not activate installed launchers or reload running Pis.

Whole-task `/review` is manual and nonblocking. Agents edit and check their work, then use
`ask_user` for completion/follow-up. Human can open `/review` at any time;
opening, closing or pasting annotations never pauses writers or starts a model turn.

## Responsibilities

- **Git owns contents/history.** Each task has one fixed committed base.
  Whole-task review compares that base with current files, including changes
  committed midway. Review never creates commits or moves an accepted baseline.
- **Diffview Plus owns presentation.** Native file panel, editable source,
  read-only historical buffers, layouts and Git operations replace custom batch
  rendering. Ordinary saves do not submit notes or finish review.
  `packages/nvim/package.nix` pins tested v0.39 source, rather than relying on
  whichever plugin version the nixpkgs input currently packages.
- **Neovim owns annotations.** Comments and original source context stay in
  memory. There are no source snapshots, review-session patches or new durable drafts.
- **Zellij transports text.** Send pastes annotations into the originating Pi
  pane and focuses it, without Enter. The human checks the input and submits.
  No saved-feedback queue or pending-review state remains.

Task isolation and independent sensitive-file/destructive-action safety gates
remain. New tasks default to `--review-mode autonomous`: no automatic per-edit
review, `request_review` tool or end-of-run checkpoint. `--review-mode guided`
restores tool-managed review after each in-scope edit/write. Ordinary guarded
sessions also review edits; ordinary `/guardian` yolo mode skips it.

Per-edit review serializes the current Pi's in-scope mutations, not other writers.
`ga` accepts; `gx`, Reject, cancellation or closing the editor review stops for
feedback and keeps saved files, including new files. Unsaved embedded-Neovim
buffers are retained. `:w` saves without accepting. No rollback occurs.
Accept refuses stale disk contents; an already-modified editor buffer is preserved
and review stops rather than replacing it. Headless in-scope mutations refuse
before writing because no review UI is available.

Existing `GUARDIAN_REVIEW_INCLUDE` / `EXCLUDE` and their `_EXTENSIONS` filters
still select reviewed files; no-op writes skip review. This is an edit/write
workflow, not a filesystem sandbox: shell/external writers are not diff-reviewed.
Agents must not use them to bypass guided review. Sensitive-path and dangerous
command gates stay independent. Opening manual `/review` never adds a writer lock.

## Launch and attach

New isolated tasks get a dedicated Zellij session per task/worktree, containing
the full editor/shell/Pi workspace. Existing tasks keep their saved session/tab
locations; there is no automatic workspace migration. `new NAME --here` uses the current
checkout and branch unchanged:
inside Zellij it stacks Pi in the existing visible Pi area without changing
editor/shell geometry or replacing processes. It requires one verified live Pi
for this checkout; missing/ambiguous Pi areas refuse rather than split an editor.
The pane command must also match a direct Pi launch, task-bound Pi launch, or
native resurrection helper. Stale herd identities pointing to editors/shells
and unrecognized custom wrappers fail closed; use `--here --tab` instead.
In a plain terminal it runs Pi directly, without Zellij or Kitty.
`--here --tab` instead requests a separate full workspace tab. Existing Pi
conversations are never rebound or sent a prompt by starting another task.

`open PATH` navigates without adoption or prompts. Unregistered checkouts get
an editor/shell workspace in their own session, not a task or Pi. Previously
opened checkouts retain their saved session/tab. Closed registered tasks require
`resume TASK_ID` to restore their conversation. Explicit paths select their
repository independently of cwd; a conflicting `--repo` fails.
`resume` focuses a verified live coordinator or attaches/switches to an exited
Zellij session's saved layout. It supplies no replacement layout, pane commands,
model override or initial prompt. Native restoration may leave commands suspended;
confirm them in Zellij after inspecting the saved command. The resurrection
extension records the active Pi transcript and task bindings; its helper validates
these before running `pi --session FILE`. The launcher does not force commands to run
or claim that Pi is alive merely because Zellij attached.

If Pi was manually closed inside a still-live workspace, or the native session
snapshot is absent, `resume` refuses with explicit recovery instructions. It
never reconstructs panes, rearranges surviving editor/shell panes, or moves a
shared task to a dedicated tab. Use a chosen terminal to run task-bound
`pi --resume` (or a verified `pi --session FILE`); never replay the original request.
Shared workspaces without a live bound Pi cannot be identified from old saved
pane IDs/anchors, so use native Zellij navigation instead. Old metadata stays
readable, but no longer authorizes pane repair.

Shared tabs use per-Pi tool-wait/question status, not competing tab-wide
`! ` cues or task-title renames. Live Pi outside its verified workspace refuses
duplicate launch; return to its existing terminal.

`pi-task --repo /path/to/repo new ...` reuses the caller's window. Inside Zellij,
it switches the current client to the saved detached task session or creates a
new session with the task workspace as its first and only tab at the selected
checkout. The initial layout is saved beside its metadata; resume never replays it. `--here` keeps stacking in the current session; `--here --tab`
keeps requesting a separate full tab there. In a plain interactive terminal,
it runs/attaches Zellij in that terminal and returns when the client exits.
Neither path requires Kitty. `--window` explicitly opens Kitty with
`--directory` so sanitized task bindings and caller Pi settings reach
the new terminal. Automation/desktop invocations without a terminal must opt in
and supply an explicit command/target, not rely on a picker.

Navigation is deliberately **single-client only**. The launcher refuses an
ambiguous current session, unknown live-session client state, or adding another
client to an already
attached destination (including `--window`). Run from that session's sole
attached terminal, or detach it manually before attaching elsewhere. No automatic
detach or client termination occurs. Checks repeat before launching/focusing;
they are observations, not an atomic client-targeting guarantee.

New isolated session names use sanitized repository/task labels plus a hash of
the task ID, so tasks within one repository get distinct sessions. Unregistered
checkout sessions use repository/checkout labels plus a checkout-identity hash.
Saved names are preserved when restoring an exited session; missing snapshots
are not replaced with newly synthesized workspaces. Legacy
repository session pointers remain a read-only fallback for old records without
an attachment; new task navigation never overwrites them. The launcher waits
up to ten seconds for exactly one attached client before creating task panes.
It never creates a headless session or passes its launch lock to the
terminal/server; plain-terminal attachment releases that lock before waiting
for client exit. `project` must be configured; Kitty is only required for
`--window`.

Alt-T retains `close_on_exit true`. Source inspection of pinned Zellij
`0ad1fa042c5284d880ac22c12b9136e174e4f9e0` (`zellij-server/src/pty.rs`)
shows its exit callback closes the picker pane by ID, not task panes created by
the server. A user-operated native scratchpad smoke using the rebuilt picker
confirmed it exits while the new task's editor/Pi/shell survive. This tested
Alt-T's lifecycle flags, not replacement of the installed keybinding command.
Do not generalize it to nested clients or other launchers; agent command panes
still retain their output. Reopen skips redundant Pi focus when changing tabs
already restored it, since native Zellij reports “already focused” as an error.

Request and model are saved before terminal/tab startup. Only `new` delivers
its request, once per launch attempt. The uncertain-delivery marker is set
immediately before pane launch, not before client startup. After failure, inspect `pi-task state
<task-id>`. Use `pi-task resume <task-id>` for a verified live Pi or an exited
Zellij session with an exact coordinator transcript recorded. Missing Pi inside
a live workspace requires explicit terminal recovery. Session headers with cwd inside the same Git worktree are valid;
other checkouts are rejected. Existing tasks with no locator, deleted transcripts,
or uncertain launches need explicit recovery: use task-bound shell or run
`cd WORKTREE && PI_TASK_ROOT=WORKTREE PI_TASK_REVIEW_STATE=REVIEW_JSON pi --resume`,
select correct session (or deliberately start fresh), then `/review-coordinator`
for ownership transfer. Never retry `new` or resend its request. `--model`
applies only to first launches; restored conversations use Pi's saved model.
Existing workspace records without
a model keep Pi's default until one is supplied on an initial launch.

After changing the launcher source, use the rebuilt package before relying on
this behavior, without activating a whole system configuration:

```bash
nix run '/home/lucas/shinyflakes?submodules=1#pi-task' -- --repo /path/to/repo new task-name \
  --base HEAD --request 'Implement the change' --model openai-codex/gpt-6.1-sol
```

For an fzf Linear ticket picker, see [Linear task setup](pi-task-linear.md).

```bash
pi-task                                      # repository/worktree picker; Alt-t also opens it
pi-task new auth-cleanup --base HEAD --request 'Refactor auth validation'
pi-task new fix-config --here --request 'Fix configuration'
pi-task new another-fix --here --tab --request 'Use a separate tab'
pi-task open ../shinyflakes.worktrees/auth-cleanup    # navigation only
pi-task resume auth-cleanup                       # live Pi or native Zellij resurrection
pi-task resume auth-cleanup --window              # explicit window; destination must be detached
pi-task state ../shinyflakes.worktrees/auth-cleanup
pi-herd                                      # running Pi instances
pi-task --repo ../shinyflakes.worktrees/auth-cleanup title 'Auth validation'

# Explicitly include existing edits in a new task's review:
pi-task --repo ../existing-task new fix-existing --here --base COMMITTED_REF --adopt include
```

Without `--here`, new tasks use `task/<name>` branches and sibling
`<main-checkout>.worktrees/<name>` directories. Starting point is committed;
main-checkout dirty edits are not copied. Committed submodules initialize
recursively. `--here` discloses existing edits and requires explicit inclusion
(`--adopt include`, or an interactive confirmation). It warns about known live
agents and offers isolation instead; this is advisory, not a writer lock or proof
that no other writer exists. Reviews include shared changes, not agent authorship.
`--adopt trust` is retired. Starting a new task never resets an earlier task's base
or coordinator.

New tasks use UUIDs independent of checkout paths. Names resolve within the
selected repository; ambiguous names or checkout paths require a picker, never
an arbitrary latest task. `PI_TASK_ROOT` is an immutable checkout binding;
`PI_TASK_REVIEW_STATE` is the exact task review identity. Only legacy path-keyed
tasks can derive state from root. Editor routing checks live tab and review
identity, handles cwd changes/restarts, and never falls back to another task's
bound editor. Shared tabs may reuse an unbound same-checkout editor. Standalone editor fallback is TUI-only;
RPC cannot launch an interactive editor on its stdout.

### Display titles and review navigation

Tab titles are human-facing, not task identity. They start with the task name
without a hash. Once intent is clear, coordinating Pi uses `set_task_title` with
a short description; children cannot rename the shared task. Naming updates
workspace metadata and any matching live tab, never branch/worktree paths,
review state, focus or agent activity. Offline naming does not launch a
workspace. New task title calls pass `--task-id` explicitly, so an older CLI
refuses rather than renaming a path-keyed legacy task. No extra model call
generates titles.

Reopening matches the original pane launch command's immutable task root and
review-state path, not current cwd, tab title or an unvalidated saved tab ID.
Zellij retains that command after cwd/title changes. Resume checks Pi separately:
a surviving editor/shell never counts as a live coordinator, and a live Pi must
report the saved active session ID/file through its instance-owned herd status.
Original pane arguments are insufficient after Pi `/new` or `/resume`; unknown
or mismatched status refuses focus and replacement. Updated Guardian must be
active in live Pi for status to include session ID/file; old runtimes fail closed
until reloaded after activation. Existing version-2 layouts
already carry task bindings. Live manual titles are preserved on reopening;
per-edit attention adds/removes only `! ` without restoring an old name.

The picker separates Start here, New isolated task and Open checkout. Task rows
show title, ID, checkout kind/path, agent status and workspace state separately,
with live activity timestamps when available. Selecting a task offers Open
workspace, Resume exact conversation or New conversation (a separate named task
in that checkout). `open` only navigates; `resume` restores a recorded session
without replaying its initial request.

`pi-herd` lists running instances, prioritizing tool approvals and open questions.
It reads instance status only, not durable task metadata. Navigate to Pi and open
`/review` there to inspect Diffview. Neither picker submits feedback.

## Review

`/review` opens native Diffview and immediately returns control to Pi.
An attached named task uses its fixed committed base; ordinary/detached
conversations use current `HEAD` on each open. A committed HEAD is required.
Review identity is the repository root plus Pi conversation ID, not a durable
pending-review record. Reopening keeps annotations while Neovim lives; their
original excerpt/revision still describes where they were written.

Pi and Neovim must occupy distinct panes in the same Zellij tab. There is no
standalone or embedded-terminal fallback: pasting to that pane would reach
Neovim instead of Pi. Missing editor/headless callers fail clearly. The installed
Zellij fork must support targeted `paste --pane-id` and `focus-pane-id`.

### Everyday actions

| Action | Command | Binding |
| --- | --- | --- |
| Comment at cursor / selection | `:PiReviewNote` / `:'<,'>PiReviewNote` | `<leader>rn` |
| List/jump/edit/delete comments | `:PiReviewComments` | `<leader>rl` |
| Paste annotations into Pi and focus it, **without Enter** | `:PiReviewSend` | `<leader>rc` |
| Close Diffview, keep annotations in memory | `:PiReviewFinish` | `<leader>rf` |

`:PiReviewSubmit` remains a compatibility alias for **paste only**, not automatic
submission. The saved-draft binding is removed. `:PiReview` offers comments,
send, repository coverage and close.

The composer supports multiline text, Ctrl-T source/task-wide scope, Ctrl-S
(or `:w`) to keep the comment in memory and Ctrl-Q to discard it. The list uses
Enter to jump, `e` to edit, `d` to delete and `q` to close. Source ranges use
extmarks and end-of-line callouts without disturbing Diffview alignment. Original
excerpts, paths, line ranges and historical/working-tree revision identity remain
attached even when source changes. No fuzzy reanchoring or source markers.

Unfinished composers block sending. Closing a view does not send, save or discard
comments. Quitting/crashing Neovim loses unsent annotations; no custom quit guard.
Source saves remain ordinary saves. They are **not** automatically attached to
feedback: annotate relevant edits explicitly. Writers keep running; refresh
Diffview and avoid overwriting concurrent changes from stale buffers.

### Direct paste, not a delivery queue

Opening passes a small JSON payload directly through Neovim's existing RPC
socket. It scans repository coverage once; it does not hash/copy source files,
create private Git object stores, write payload/response files, take reviewer
leases, or wait for a review decision.

Send formats only the annotations and calls:

```bash
zellij --session "$session" action paste --pane-id "$pane" -- "$feedback"
zellij --session "$session" action focus-pane-id "$pane"
```

No shell interpolation of feedback, raw keystroke typing, Enter, input clearing,
new socket server or mailbox is involved. Terminal control characters are rejected
so excerpts cannot terminate bracketed paste. New reviews create no durable drafts,
submissions or receipt tracking.

Before paste, Neovim checks the **existing** instance-owned herd status file:
Pi PID, conversation ID, Zellij session/pane, process liveness and live terminal
pane membership. Exited/held panes, changed sessions and known tool dialogs
refuse delivery. This is status inspection, not a feedback-file handoff.

CLI success clears only the pasted annotations. Failed paste retains them.
If focus fails afterward, report that text was already pasted; do not invite
duplicate sending. The human checks Pi's editor and presses Enter.

This is not atomic process/session targeting or proof of Pi receipt. A concurrent
session switch, human typing or dialog can race the checks; existing input may
be combined with the pasted annotations. Nothing promises restart-safe delivery.
Switching Pi conversations never intentionally retargets an old annotation buffer.

### Git coverage

Parent Diffview Plus v0.39 hides untracked files and submodule contents in
fixed-base comparisons. The repository picker/report remains:
- Register new files explicitly with `git add -N -- <path>`, then refresh.
  Review never stages files automatically.
- Open initialized submodules against their gitlinks at the selected base.
  Nested submodules are discovered recursively; newly added ones use the empty tree.
- Removed/uninitialized/missing-base repositories remain explicit unavailable
  entries. Their contents are not claimed as reviewed.
- Reopen after index/submodule topology changes to regenerate coverage.

Coverage is informational, not a finish/approval gate. Conflicts, unsupported
index flags, unsafe repository roots and non-UTF-8 paths still fail closed rather
than silently narrowing the view. There is no immutable-tree attestation.

## Task metadata

Version-3 task metadata contains only task ID (when present), checkout root,
fixed committed base, guided/autonomous policy and coordinator/transcript binding.
`/review-coordinator` explicitly transfers naming/resume ownership without
starting work. It is available only in task-bound Pi sessions. Manual `/review`
does not mutate metadata or route annotations through a coordinator.

Version-2 metadata is projected onto this reduced contract when read and
persisted under the existing state lock by CLI state access or session binding.
**Old drafts, submissions, pending reviews, counters and adoption/archive metadata
are discarded without backup.** Task identity, base, policy and coordinator
binding remain unchanged. Corrupt identity/base/policy fails closed; it is never
replaced with a guessed base.

The mailbox, receipt tracking, review leases, `/review-feedback`, `pi-task review`,
`pi-herd --reviews` and manual `pi-task migrate` operation are removed. Version-1
private dirty/trusted baselines are not supported; start a new task with an
explicit committed base instead. Unreferenced old session-review files, snapshot
directories and Git retention refs are not scanned or used. This transition does
not delete worktrees, source files, transcripts or Git refs.

## Activation

Activate the updated `pi-task` and `pi-herd` packages before reloading Guardian
in task sessions. The shared `~/.pi/agent/lib` link must be installed too.
**Do not mix old Guardians/CLIs with upgraded task metadata:** the old schema
validator rejects version 3. Reload all Pis sharing a task together; old feedback
cannot be recovered after transition.

`pi-task` bundles its CLI/shared TypeScript sources and ESM manifest, runs with
Nix-pinned Node native type stripping, and needs no global Node or compiler.
Source changes alone do not update that installed CLI. Use `pi-task state TASK`
to explicitly upgrade/inspect metadata without launching or resuming Pi.

Manual annotations remain memory-only. Activate/restart the current Neovim plugin
before reloading Guardian if still using an old rollback-capable per-edit bridge.

## Validation

```bash
export DIFFVIEW_TEST_RTP="$HOME/.btca/agent/sandbox/dlyongemallo-diffview-plus.nvim"
bash -n packages/pi-task.sh packages/pi-task-state.sh packages/pi-herd.sh packages/tests/pi-task-*.sh
bash packages/tests/pi-task-resume.sh
bash packages/tests/pi-task-loader.sh
node --experimental-strip-types --test modules/aspects/agents/pi/cli/tests/*.test.ts \
  modules/aspects/agents/pi/extensions/tool-guardian/tests/*.test.ts \
  modules/aspects/agents/pi/tests/zellij-resurrect.test.ts
nix build --offline --builders '' --no-link \
  '.?submodules=1#pi-task' '.?submodules=1#pi-herd' '.?submodules=1#pi-guardian-nvim' '.?submodules=1#nvim'
nix run --offline '.?submodules=1#nvim' -- --headless \
  '+lua if vim.fn.exists(":PiReviewNote") ~= 2 then vim.cmd("cquit 1") end' '+qa'
```

Guardian checks cover memory-only task/ordinary review, writes during review,
guided per-edit review and preserve-on-reject behavior, HEAD versus fixed task
bases, coordinator/restart binding, metadata transition, sensitive paths and destructive-command approvals. Native
Neovim coverage requires `DIFFVIEW_TEST_RTP`; without it that test is skipped.

`pi-task-resume.sh` also checks presentation with stub Zellij/Kitty and a
real PTY: native exited-session delegation without layout replacement, missing-Pi
refusal with unchanged survivor panes, plain-terminal lifetime and lock release,
explicit windows, per-task sessions, checkout startup cwd, stable live navigation,
legacy metadata, unknown/multiple/racing clients, initial-launch readiness failures
and picker exit. Native restoration is stubbed here; no real user sessions are touched.
These automated checks do not replace live client/focus/lifecycle verification.

Shared contract fixtures exercise the single validator through both consumers.
The loader fixture uses isolated offline Pi with Home Manager-style symlinks,
no model prompt and no persisted session. State tests cover automatic metadata
transition, discarded old feedback, dirty adoption, mixed Bash/Node lock contention,
concurrent coordinator binding and rejection of removed operations. To repeat focused
state/Guardian checks against the packaged CLI (including empty-PATH state
operations outside the source checkout):

```bash
package=$(nix build --offline --builders '' --no-link --print-out-paths '.?submodules=1#pi-task')
PI_TASK_TEST_CLI="$package/bin/pi-task" node --experimental-strip-types --test \
  modules/aspects/agents/pi/cli/tests/task-state.test.ts \
  modules/aspects/agents/pi/extensions/tool-guardian/tests/task-review.test.ts
```

Metadata cache tests cover unchanged reads, explicit refresh, atomic replacements
and corrupt/missing state. Review tests cover no snapshots/state writes, native
Diffview annotations on both revisions, close/reopen, paste-only argument
dispatch, failed paste retention, focus failure, stale identity, terminal-control
rejection and recursive submodule coverage. Live Zellij-to-Pi paste remains a
separate human smoke check.

### Human smoke results

- **2026-10-15:** edit → feedback → model revision confirmed with human edits
  preserved.
- **2026-10-16, autonomous:** fresh task launched with one registered Markdown
  file and the review → human edit → request changes → revision → finish smoke
  procedure. User reported that the flow worked cleanly.
- **2026-10-16, guided:** fresh task launched with guided file creation and edit,
  followed by whole-task review. User accepted the overall workflow afterward.

These historical results describe the old approval-gated workflow, not validation
of the current nonblocking whole-task review or preserve-on-reject guided behavior.

Implementation: `modules/aspects/agents/pi/cli/{pi-task,review,runtime}.ts`,
`modules/aspects/agents/pi/lib/task-state.ts`, Guardian task/batch modules and
`modules/aspects/agents/pi/extensions/tool-guardian/review-session.ts`,
`packages/pi-guardian-nvim/lua/pi-guardian/{batch,batch-notes}.lua`,
`packages/pi-guardian-nvim/lua/pi-review/comments.lua`, and
`packages/nvim/lua/cfg/diffview.lua` (loaded by `packages/nvim/init.lua`).
Existing workspace launcher, Zellij routing and native review bridge are reused.

### BTCA source verification

- Diffview Plus v0.39, commit
  [`2a2d89a`](https://github.com/dlyongemallo/diffview-plus.nvim/tree/2a2d89a07f5d5d3cef7f542b99c3e28050ca205c):
  [editable source/LSP](https://github.com/dlyongemallo/diffview-plus.nvim/blob/v0.39/USAGE.md#comparing-all-the-changes),
  [untracked/submodule behavior](https://github.com/dlyongemallo/diffview-plus.nvim/blob/2a2d89a07f5d5d3cef7f542b99c3e28050ca205c/lua/diffview/vcs/adapters/git/init.lua#L2532-L2592),
  [historical buffer protection](https://github.com/dlyongemallo/diffview-plus.nvim/blob/2a2d89a07f5d5d3cef7f542b99c3e28050ca205c/lua/diffview/vcs/file.lua#L63-L69).
- Pi commit
  [`6a1f799`](https://github.com/earendil-works/pi/tree/6a1f799b675c8cb98320b71ff7ee44f160fe8d66):
  [fire-and-forget extension dispatch](https://github.com/earendil-works/pi/blob/6a1f799b675c8cb98320b71ff7ee44f160fe8d66/packages/coding-agent/src/core/agent-session.ts#L3427-L3435),
  [extension events precede persistence](https://github.com/earendil-works/pi/blob/6a1f799b675c8cb98320b71ff7ee44f160fe8d66/packages/coding-agent/src/core/agent-session.ts#L1143-L1166).

No agent-companion plugin is needed for paste-only Pi/Zellij delivery.

## Boundaries and follow-ups

Commit, merge, deployment, restore and worktree deletion remain explicit human
Git/system operations. Closing a tab or session never deletes its worktree. No accepted-tree
snapshots, custom diff renderer, annotation-thread lifecycle, automatic rollback,
agent scheduler/dashboard or custom cursor/layout restoration was added.

Optional follow-ups, not blockers for the accepted workflow: delegation skill;
Claude integration. Advisory small-model
risk/understanding ranking must never grant permissions, hide unhighlighted
changes or replace reading diff.
