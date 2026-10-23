# Worktree-attached agent review workflow

For remaining redesign steps, see [Pi task workflow redesign](pi-task-workflow-redesign.md).
Step 1 (reliable resume) exists in source; same-window startup and shared-checkout
task identities remain proposals. Installed packages still require rebuild/activation.

Review is manual and nonblocking. Agents edit and check their work, then use
`ask_user` for completion/follow-up. Human can open `/review` at any time;
opening, closing, submitting or finishing review never pauses writers.

## Responsibilities

- **Git owns contents/history.** Each task has one fixed committed base.
  Whole-task review compares that base with current files, including changes
  committed midway. Review never creates commits or moves an accepted baseline.
- **Diffview Plus owns presentation.** Native file panel, editable source,
  read-only historical buffers, layouts and Git operations replace custom batch
  rendering. Ordinary saves do not submit notes or finish review.
  `packages/nvim/package.nix` pins tested v0.39 source, rather than relying on
  whichever plugin version the nixpkgs input currently packages.
- **Neovim glue owns feedback.** Select source, compose remarks, save Markdown
  draft, submit bundled feedback for revision. No source markers, thread IDs,
  resolved/outdated lifecycle, reanchoring, live snapshot synchronization or
  per-save human-edit journal.
- **Pi owns feedback routing.** Submitted comments reach the coordinating
  session. Finish does not commit, deploy or start a model turn.

Task isolation and independent sensitive-file/destructive-action safety gates
remain. There is no automatic per-edit review, rollback, `request_review` tool
or end-of-run checkpoint. Legacy `--review-mode autonomous|guided` values stay
accepted as metadata only; neither enables approval gates.

## Launch and attach

One repository Zellij session contains one tab per task/worktree. Each tab owns
its editor, terminal and agent panes. `open` navigates to an existing workspace
without sending prompts (first-time worktree adoption retains legacy behavior);
`resume` focuses its live coordinator or restores only
missing Pi (or the whole layout) with native `pi --session` and no prompt.
Main checkout remains usable.

`pi-task --repo /path/to/repo new ...` handles session setup even when called
from another repository or outside Zellij. It opens a footclient window with
Zellij's `project` layout at the main checkout when the repository session is
missing, or attaches a window when the session has no client. New sessions use
the repository basename (unsupported characters become hyphens). The launcher
waits up to ten seconds for an attached client before creating a separate task
tab. It never creates a headless session or passes its launch lock to the
terminal/server. `footclient` and the configured `project` layout must be
available in the desktop session.

Request and model are saved before terminal/tab startup. Only `new` delivers
its request, once per launch attempt. After failure, inspect `pi-task state
<worktree>` and use `pi-task resume <worktree>` if an exact coordinator transcript
was recorded. Session headers with cwd inside the same Git worktree are valid;
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
pi-task open ../shinyflakes.worktrees/auth-cleanup    # navigation only
pi-task resume auth-cleanup                       # live Pi or exact transcript
pi-task state ../shinyflakes.worktrees/auth-cleanup
pi-task review                               # pending tasks in this repository
pi-herd --reviews                             # pending reviews in running Pi instances
pi-task --repo ../shinyflakes.worktrees/auth-cleanup title 'Auth validation'

# First adoption of an existing dirty worktree:
pi-task open ../existing-task --base COMMITTED_REF --adopt include
```

New tasks use `task/<name>` branches and sibling
`<main-checkout>.worktrees/<name>` directories. Starting point is committed;
main-checkout dirty edits are not copied. Committed submodules initialize
recursively. Dirty adoption includes existing edits in review, without claiming
agent authorship. `--adopt trust` is retired. Reopening/policy changes cannot
reset an existing task base.

`PI_TASK_ROOT` is immutable task identity; `PI_TASK_REVIEW_STATE` locates durable
state. Already-attached panes can derive state path from task root. Editor
routing checks live task/tab identity, handles cwd changes/restarts, and never
falls back to another task's editor. Standalone editor fallback is TUI-only;
RPC cannot launch an interactive editor on its stdout.

### Display titles and review navigation

Tab titles are human-facing, not task identity. They start with the task name
without a hash. Once intent is clear, coordinating Pi uses `set_task_title` with
a short description; children cannot rename the shared task. Naming updates
workspace metadata and any matching live tab, never branch/worktree paths,
review state, focus or agent activity. Offline naming does not launch a
workspace. No extra model call generates titles.

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
review attention adds/removes only `! ` without restoring an old name.

The existing task picker lists pending reviews first with `REVIEW`, title,
summary and worktree path. `pi-task review` filters that repository to pending
tasks, including tasks whose Pi is closed. A live Pi receives no new prompt;
`open` only navigates. Use `resume` to restore a recorded session; it never
replays request or saved feedback.
Saved review drafts remain intact. `pi-herd` puts whole-task reviews ahead of tool
approvals and shows their summaries; `--reviews` filters running instances
(and combines with `--dmenu`). It revalidates durable state rather than trusting
cached pending status. Navigation focuses the workspace/instance only: open
`/review` there to inspect Diffview. Neither picker submits feedback or starts work.

## Review

Human `/review` opens or reopens native Diffview. Task workspaces compare the
fixed committed task base with current files. Ordinary Git sessions compare
against `HEAD` captured when a fresh review opens. Reopening an unfinished
review preserves its base, comments and source-change baseline; after finishing,
the next ordinary review resolves the current `HEAD` again.

Ordinary review state is isolated by repository and Pi session under
`<git-common-dir>/pi-task/session-reviews/<hash>.json`; it never adopts a
worktree or changes a task's fixed base. Outside a Git repository, `/review`
fails without affecting editing. A repository must have a committed `HEAD`.

A reviewer lease excludes competing UIs for the same review state, not writers.
There are no writer leases, generation tracking or content fingerprints on tool
calls. Short metadata locks protect drafts and receipts only. Same-task children
still inherit task identity and obey parent coordination.

Neovim owns review decisions; no Pi selector occupies the agent's dialog while
review is open. With no attached editor, interactive Pi launches standalone
Neovim asynchronously; RPC requires an existing editor. Review can remain open
while the agent continues. Refresh Diffview as files change and avoid saving
stale source buffers over concurrent edits.

### Four everyday actions

Normal Diffview bindings stay unchanged:

| Action | Command | Binding |
| --- | --- | --- |
| Comment at cursor / visual selection | `:PiReviewNote` / `:'<,'>PiReviewNote` | `<leader>rn` |
| Inspect/edit accumulated feedback | `:PiReviewDraft` | `<leader>rd` |
| Request changes: submit comments + review-session edits for revision | `:PiReviewSubmit` | `<leader>rc` |
| Finish without sending or starting a model turn | `:PiReviewFinish` | `<leader>rf` |

`:PiReview` opens secondary tools: Feedback, Delivery history, Repositories /
coverage, and Recovery help. Closing review tab keeps notes and baseline for
reopening; it never restores source or pauses writers. Ask questions directly
in coordinating Pi, not through a second editor Send path.

Finish, Request changes and repository navigation require an open `/review`.
Comments and feedback also work in task source buffers outside review. Editors
must be task-bound (or explicitly opened by Pi for review); arbitrary-editor
routing and target picker are removed. Neovim validates review decisions before
submitting them. Source saves remain ordinary saves. Modified task source and unadded comments must be saved/added or
explicitly discarded before finishing.

Comment dialog accepts multiline text. File, cursor line/selected range,
displayed excerpt and working-tree/historical revision identity attach
automatically. Ctrl-T toggles source/task-wide scope without changing comment
text; non-source buffers start task-wide. Title shows current scope. References
remain recorded context, not live anchors after edits.

Inside dialog: Ctrl-S (or `:w`) adds comment to durable feedback and closes;
Ctrl-Q discards only that comment. Nothing reaches Pi until Request changes
submits the bundle. Unadded comments block decisions and do not survive editor
restart. Feedback saves never send it. Finish warns when saved feedback remains;
confirming keeps it unsent for later without a model turn.
Saved feedback survives review close and process restart. Concurrent draft
overwrites fail rather than silently losing another editor's notes; preserve
local text, discard stale buffer and reopen/merge feedback.

### Review-session source edits

First `/review` opening captures one private baseline for that pending review.
Close/reopen and process restart keep it; reopening never resets it.
Request changes attaches a Git diff from that baseline to current saved files,
alongside comments. Source edits alone are sufficient; empty comments plus no
session changes refuse submission and keep the review open. Feedback view edits
comments; source diffs attach automatically at submission.

Capture covers available repositories recursively, Git-tracked and non-ignored
untracked files, raw source bytes, symlinks and executable modes. Files already
captured stay in scope if later ignored. Added/deleted files and submodule
changes are included; binaries get change notices, not inline payloads.
Unavailable submodule contents are explicitly incomplete. Existing sensitive
path guards exclude contents; changed protected paths get notices only.
Ignored files outside the baseline are not automatically captured.

Baseline lives beside task JSON at `<task-id>.json.session/`, mode `0700`, using
isolated commit-less Git object stores. Source index, refs and object database
are untouched; no commits or accepted-content history are created. Successful
Request changes first persists the complete submission, then removes baseline;
Finish removes it without sending or starting a model turn. Unconfirmed queued
submissions retain complete diff text for explicit recovery. Treat active
baseline as private source data, not disposable runtime IPC.

Source files already contain edits. Feedback explicitly tells model to reread
and preserve them, **not apply the supplied patch again**. Session changes are
context, not proof of human authorship: agents and other processes can keep
writing during review. Capture is not an atomic snapshot across all files. No reconstruction or automatic rollback occurs. Use
ordinary Git/Diffview restore/hunk operations only with awareness of affected
human edits. Closing review never restores files.

### Coverage: new files and submodules

Diffview Plus v0.39 hides untracked files in commit-to-worktree comparisons and
uses `--ignore-submodules`. Parent view alone is **not recursive coverage**.
Bridge discovers these independently and exposes a coverage report/picker.

- Register new files explicitly with `git add -N -- <path>` (or ordinary
  staging), then refresh Diffview. Review itself never runs `git add`.
  Untracked files in available repositories block finishing review until
  registered or intentionally ignored; agent work continues regardless.
- Each initialized submodule gets its own view against gitlink at task base.
  Nested submodules are discovered recursively. Newly added modules compare
  against native empty tree, so their contents are additions, not silently
  treated as an already-reviewed repository.
- Coverage report records base/index/worktree gitlinks. Removed, renamed and
  uninitialized modules, or missing base objects, remain visible as unavailable
  entries when no view can be opened. Finishing requires explicit Pi confirmation
  that their removal/gitlink changes were reviewed separately; unavailable
  contents are never represented as reviewed recursively.
- After changing submodule/index topology, close/reopen `/review` to regenerate
  manifest. Ordinary file saves refresh native diff in place.
- Conflicts, assume-unchanged/skip-worktree flags, unsafe repository roots and
  non-UTF-8 Git paths fail closed instead of silently narrowing review.

No immutable-tree attestation is claimed: agents and other processes can change files.
Finish is a human workflow signal, not proof every byte or hunk was inspected.

## Feedback delivery and recovery

First task Pi session binds coordinator identity. Reviewing child cannot steal
it. Task-bound editor routes to saved coordinator, never whichever pane is
focused. Unbound editors cannot pick arbitrary tasks.

- Questions go directly to coordinating Pi. Legacy queued question submissions
  remain readable/retryable.
- `:PiReviewSubmit` durably queues saved draft plus review-session source diff
  for revision. Source is kept. No commit or merge is implied. Revisions end with
  `ask_user`, not another approval request.
- `:PiReviewFinish` closes review only. Idle agent remains idle until prompted.
- Failed/queued-only submissions remain unconfirmed in menu's Delivery history.
  Submitted draft is retained until transcript receipt is confirmed; newer draft edits are never
  cleared by an older receipt.
- Restart holds saved unconfirmed submissions; `/review-feedback` explicitly
  retries. `/review-coordinator` confirms transfer to current Pi session without
  starting work. Explicit retries may duplicate already-queued delivery; unique
  submission IDs distinguish them.

Delivery requires complete submission in coordinator user message: persisted
transcript for saved sessions, session entries for ephemeral ones. Merely calling
Pi's send API or observing `message_end` is not a durable acknowledgement.

Durable version-2 JSON lives at
`<git-common-dir>/pi-task/reviews/<task-id>.json`: fixed base, pending review,
coordinator, its exact native Pi transcript path (when available), Markdown
draft/version and immutable submission texts/receipts.
Policy and generation fields are retained for version-2 compatibility only;
they no longer control tools. Ordinary reviews use the session-scoped path above. Draft opens as a Markdown `acwrite` buffer; it is not
source or an annotation database. Runtime IPC stays instance-owned and separate
from durable state and workspace attachment metadata.

### State contract and polling

Bash remains the sole state-mutation authority. Shared valid/invalid fixtures at
`modules/aspects/agents/pi/extensions/tool-guardian/tests/fixtures/task-review-state.json`
exercise both Bash and TypeScript validators. State is one JSON document;
counters are nonnegative safe integers, reviewed generation cannot exceed
current generation, and pending review IDs must be nonempty. Missing/null
optional fields remain supported. Lua checks version/root and delegates
mutations to Bash; it does not duplicate the full validator. Storage stays
version 2, with no new schema runtime or migration.

The mailbox keeps its 500 ms poll to discover cross-process submissions and
confirm durable transcript receipts. State reads reuse validated, frozen
records while file metadata is unchanged. Transcript text is cached only for
saved sessions and checked only with unconfirmed submissions. Cache keys include
device, inode, size, and nanosecond modification/change times, so atomic
replacement, truncation and same-size rewrites invalidate them. Missing or
invalid state never falls back to cached contents. These keys are local change
detection, not content attestation.

Startup refreshes caches without resuming saved work. Explicit feedback retries
bypass caches; ephemeral sessions inspect current in-memory entries each time.
Complete coordinator user-message text is still required for acknowledgement.
The same mailbox poll refreshes tab/herd attention after another cooperating Pi
finishes review, even when the coordinator is idle. No watcher, event bus or
additional background service is introduced.

Submission history still grows indefinitely. Measure representative long-task
state size and delivery cost before adding archival or incremental transcript
parsing; no automatic pruning is performed.

## Activate and migrate legacy tasks

Build/activate updated `pi-task` and Neovim configuration through usual Home
Manager flow. Activate updated `pi-task` before `/reload` in every Pi, including
children; the installed helper must support ordinary-session `init`/`begin-local`.
Reload does not migrate or discard saved version-2 drafts. Old running Guardians
still enforce their old gates until reloaded. Restart Neovim after plugin changes.

Legacy task migration is explicit because private dirty/trusted baselines cannot
be reinterpreted as committed task bases safely:

```bash
pi-task migrate ../shinyflakes.worktrees/old-task --base CHOSEN_COMMIT
pi-task open ../shinyflakes.worktrees/old-task
```

Migration retains pending review, coordinator and submission history; converts
legacy task/line annotations into plain Markdown with recorded context; copies
entire original JSON to adjacent `.v1.json`. Source contents, user index and old
Git retention refs are untouched. Backup collision, corrupt state or invalid
commit refuses migration. Migration does not launch or resume Pi. Historical
human-save patches/private snapshot metadata remain in backup rather than being
replayed. No automatic legacy-state/ref deletion is performed.

Old private snapshots may contain sensitive previously untracked files. Keep
`refs/pi-task/` local; do not mirror-push them. Cleanup of archives/refs remains
an explicit separate Git/data-retention operation.

## Validation

```bash
export DIFFVIEW_TEST_RTP="$HOME/.btca/agent/sandbox/dlyongemallo-diffview-plus.nvim"
bash -n packages/pi-task.sh packages/pi-task-state.sh
bash packages/tests/pi-task-resume.sh
node --experimental-strip-types --test modules/aspects/agents/pi/extensions/tool-guardian/tests/*.test.ts
nix build --offline --builders '' --no-link \
  '.?submodules=1#pi-task' '.?submodules=1#pi-herd' '.?submodules=1#pi-guardian-nvim' '.?submodules=1#nvim'
nix run --offline '.?submodules=1#nvim' -- --headless \
  '+lua if vim.fn.exists(":PiReviewNote") ~= 2 then vim.cmd("cquit 1") end' '+qa'
```

Guardian checks cover manual task/ordinary review, writes during review,
legacy guided metadata, HEAD refresh versus fixed task bases, coordinator and
restart delivery, sensitive paths and destructive-command approvals. Native
Neovim coverage requires `DIFFVIEW_TEST_RTP`; without it that test is skipped.

Shared contract fixtures exercise both state validators. Cache tests cover
unchanged polls, explicit refresh, atomic replacements and corrupt/missing
state. Review-session checks cover edits-only delivery, saved/restarted
baselines, large payloads, sensitive exclusions and submodule coverage without
source Git mutations. Human smoke remains separate from automated checks.

### Human smoke results

- **2026-10-15:** edit → feedback → model revision confirmed with human edits
  preserved.
- **2026-10-16, autonomous:** fresh task launched with one registered Markdown
  file and the review → human edit → request changes → revision → finish smoke
  procedure. User reported that the flow worked cleanly.
- **2026-10-16, guided:** fresh task launched with guided file creation and edit,
  followed by whole-task review. User accepted the overall workflow afterward.

These historical results describe the retired approval-gated workflow, not
validation of the current manual/nonblocking behavior.

Implementation: `packages/pi-task{,-state}.sh`, Guardian task/batch modules and
`modules/aspects/agents/pi/extensions/tool-guardian/review-session.ts`,
`packages/pi-guardian-nvim/lua/pi-guardian/{batch,batch-notes}.lua`, and
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

No agent-companion plugin is needed for durable Pi/Zellij delivery.

## Boundaries and follow-ups

Commit, merge, deployment, restore and worktree deletion remain explicit human
Git/system operations. Closing tab never deletes worktree. No accepted-tree
snapshots, custom diff renderer, annotation-thread lifecycle, automatic rollback,
agent scheduler/dashboard or custom cursor/layout restoration was added.

Optional follow-ups, not blockers for the accepted workflow: delegation skill;
Claude integration. Advisory small-model
risk/understanding ranking must never grant permissions, hide unhighlighted
changes or replace reading diff.
