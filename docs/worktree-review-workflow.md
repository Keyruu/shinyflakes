# Worktree-attached agent review workflow

Status: stage 1 and stage-2 review-state foundations manually verified by the
user. Autonomous checkpoint slice implemented and automated checks pass; manual
checkpoint smoke check remains. Full stage-2 review UI and stage 3 remain planned.

## What we have now

| Area | Current implementation |
| --- | --- |
| Task launch | `pi-task` creates or opens worktrees; shell command and Alt-t picker share one path. |
| Isolation | Task-specific editor, terminal, and Pi tab; committed starting point; recursive submodule initialization. |
| Attachment | Existing workspace is focused rather than duplicated; requests are saved but never replayed on reopen. |
| Review routing | Guardian selects Neovim from the live task tab and task identity, including editor cwd changes/restarts. |
| Concurrent Pi | Runtime-owned IPC files prevent one instance from deleting another's pending review. |
| Existing review | Guided per-edit review remains; literal agent-authored annotation-marker text is preserved. |
| Review state | Saved policy, starting/accepted Git snapshots, dirty-worktree adoption, and durable pending checkpoints. |
| Checkpoints | Manual `/review`, agent `request_review`, and final-settlement fallback; cooperating task writers pause across restart. |
| Batch review | Complete unified checkpoint patch in task Neovim; accept, request changes, or pause, always keeping files. |
| Zellij | Home Manager and launcher use the same fork required by the configured bindings. |
| Validation | 197 Guardian tests, real Git/submodule/lease checks, native Neovim batch and Pi RPC smoke, launcher checks, package builds, Biome and ShellCheck pass. |

**Not implemented yet:** changed-file navigation/side-by-side batch UI,
diff-scope toggle, hunk/file revert, pending-review picker routing, dedicated
annotations/drafts, coordinator feedback routing, or delegation skill. Durable
review state remains separate from attachment metadata and runtime IPC.

Commit, merge, and cleanup remain manual Git operations. No automatic deployment
or worktree deletion was added.

The sections below describe the **target workflow**, except where implementation
status explicitly says otherwise.

## Next steps, in order

Stage-1 and state/baseline smoke checks passed. Checkpoint slice was approved
and implemented below. Confirm another slice before coding it.

1. **Manually verify checkpoint slice.** Activate updated helper/plugin and
   reload Pi. Check tool/shell/committed changes, close/reopen and Pi restart
   while pending, same-task writer pause, acceptance, and independent safety
   approvals. Background requests mark pending without switching tasks.
2. **Complete stage-2 review UI and navigation.** Add changed-file list,
   side-by-side diff, request/rationale/checks, whole-task/checkpoint toggle,
   hunk/file revert, and pending-review picker routing without cross-task focus
   stealing. Validate committed, shell-produced, added/deleted, renamed, and
   binary changes, plus recovery while review is pending.
3. **Implement stage 3: feedback and revision.** Add dedicated inline/task
   comments and questions, persistent drafts, direct-edit feedback, outdated
   comment handling, and submission to coordinating Pi. Add a delegation skill,
   not a child-agent scheduler. Verify the full review → revise → review loop.
4. **Only then explore follow-ups.** Small-model risk/understanding highlights,
   Claude integration, and optional true pre-write protection remain separate.

## Goal

Run independent agent tasks in isolated Git worktrees, switch into the correct
editor and terminals effortlessly, understand each change set, and send precise
review feedback without approving every file edit.

Task isolation is the primary improvement. Summaries and annotation support it;
they are not a replacement for reading the diff.

## Workspace model

- One Zellij session per repository/project.
- One Zellij tab per task/worktree.
- Each task tab owns its Neovim process, bottom terminal area, and agent stack.
- Keep the familiar editor/terminal/agent layout. Switching tasks switches the
  entire workspace, rather than changing the directory of a shared editor.
- Independent tasks use separate worktrees. Opening an already attached
  worktree focuses its existing workspace instead of creating a duplicate.
- The ordinary main-checkout workspace remains usable and is visibly distinct
  from isolated task workspaces.
- Pi gets integrated review first. Worktree/workspace attachment should not
  depend on the agent being Pi; Claude integration comes later.

## Launch and attachment

Provide a shell entry point and a hotkey/picker using the same launch path:

1. Select repository.
2. Create a task or open an existing worktree.
3. For a new task, supply a name and optionally a request.
4. Open the task workspace. Start Pi on the request only when one was supplied;
   otherwise open idle for prompting.

New tasks start from a chosen commit. Do not silently copy uncommitted changes
from the main checkout.

When adopting an existing dirty worktree, explicitly choose whether to include
existing edits in the first review or trust the current state as the starting
baseline. Preserve their provenance; do not attribute pre-existing edits to the
agent. Trusted current state can differ from HEAD.

## Review policy

Policy is per task and survives reopening:

| Mode | Behavior |
| --- | --- |
| Autonomous, default | Agent works until a review checkpoint; review a coherent batch. |
| Guided | Preserve existing guardian per-edit review behavior. |

Existing guided review writes the proposed file before review and restores it
on rejection. It is not a pre-write protection boundary. A true pre-write gate
is a separate follow-up, not part of this rework.

Autonomous mode must not be implemented as a blanket alias for current `yolo`
mode. Destructive actions, sensitive access, and external effects retain
explicit safety gates independently of how often code is reviewed. Ordinary
review acceptance does not authorize deployment or other external actions.

Autonomous checkpoints:

- Agent explicitly requests review at a meaningful point.
- End of a user-request run requests review if unreviewed changes remain.
- Human can request review manually.
- No arbitrary timer or diff-size interruptions.

Opening review pauses task writing until feedback is submitted or review is
accepted. Independent tasks continue. Finish or account for in-flight writes
before presenting a stable diff; submitting a review must not race a write.

## Child agents: skill, not orchestration framework

The coordinating agent may start visible child agents in the task's agent
stack and worktree, including writers. Parent coordinates editing responsibilities
and pause/resume through an agent skill/convention.

- No enforced single-writer lock, scheduler, or agent-tree framework.
- Concurrent writers inside a task can conflict; parent owns coordination.
- Same-task children cooperate with the task-wide review pause.
- Review feedback returns to the coordinating Pi, which delegates fixes.
- Children do not independently resume writing while review is pending.
- Independent delegated tasks can use their own worktrees/tabs through the
  normal launch path.

This is cooperative coordination, not a hard cross-process guarantee. Unrelated
processes and agents ignoring the convention can still mutate files.

## Review experience

Review opens in the task's existing Neovim, in a review tab containing:

- Changed-file list and selected file's side-by-side diff.
- Original request, brief behavior/rationale summary, and checks run/not run.
- Inline comments/questions and a task-wide feedback view.
- Ordinary editable code buffers for direct human changes.

Show both diff scopes with a toggle:

1. **Since last accepted checkpoint**, the default.
2. **Whole task**, against the task starting baseline.

Baselines are independent of subsequent Git commits. Committing midway must
not hide unreviewed changes. Include worktree changes regardless of whether
`edit`, `write`, shell commands, or another tool produced them: additions,
deletions, renames, and committed changes all matter. Binary changes must be
identified rather than silently omitted from review.

Baseline advancement happens on acceptance, not when merely opening or closing
review. Incorporate accepted human edits into the checkpoint. Whole-task
starting baseline remains available.

### Feedback and revision

- Attach dedicated comments/questions to a selected line or hunk; support
  multiline comments and a task-wide note.
- Do not insert annotations into source files or rely on stripping `ai:` lines.
- Accumulate feedback and submit it in one action.
- Send comments/questions and the human's direct-edit diff to coordinating Pi.
- Preserve unresolved comments across revisions. If their context disappeared,
  show them as outdated; never silently attach them to unrelated lines.
- Diff remains the source of truth; summary does not replace scrutiny.

Review actions:

| Action | Result |
| --- | --- |
| Accept and continue | Advance accepted checkpoint; permit task to continue. |
| Submit feedback / request changes | Keep files and human edits; resume coordinator to answer questions or revise. |
| Stop task | Keep files and review state; remain paused. |
| Close review without submitting | Preserve draft comments and pending review; remain paused. |

Requesting changes does not automatically roll back the batch. Revisions are
reviewed again through the same checkpoint loop.

### Revert

Provide easy current-hunk and current-file revert against the **displayed**
baseline. Toggling diff scope therefore changes the revert target; make that
scope visible when reverting.

- Update the diff immediately after revert.
- Revert does not accept review or resume agents.
- Make affected human edits visible before discarding them; never imply revert
  preserves edits inside the selected hunk/file.
- Human can annotate after reverting and submit explanatory feedback.
- Whole-batch revert is intentionally omitted.

## Attention and navigation

A review request from another task must not steal focus:

- Pause that task and mark it pending.
- Show pending-review status/notification.
- Picker selection jumps into that task's review, not merely its agent pane.
- Explicit review in the current task opens immediately.

Extend existing navigation rather than build a separate dashboard. Existing
`pi-herd` already lists running Pi instances and jumps to their panes; task
attachment and pending-review navigation can build on it.

## Persistence and Git lifecycle

Persist task request, review mode, starting/accepted baselines, draft comments,
and pending-review state per task. Reopening a workspace or restarting Pi opens
idle/paused; never silently resume agents.

Use existing editor/Zellij behavior for exact cursor and layout restoration
rather than adding a custom restoration system.

Review acceptance is separate from commit, merge, deployment, and cleanup:

- First version leaves commit/merge to explicit existing Git tools/lazygit.
- Closing a tab does not delete its worktree.
- Worktree cleanup is explicit and refuses dirty or unmerged work unless
  deliberately overridden.

## Implementation sequence

Each slice must work independently before adding the next. Stage 1 and state
foundations were manually verified; checkpoint slice now awaits manual smoke.
Confirm the next UI/navigation slice before proceeding.

### 1. Worktree-attached workspaces

Implemented `pi-task` with repository/worktree picker on **Alt-t** after Home
Manager activation. Ordinary project layout and existing guided review remain
unchanged; autonomous default arrives in stage 2.

```bash
# Available immediately without activating Home Manager:
nix run '.?submodules=1#pi-task' -- new auth-cleanup --request 'Refactor auth validation'
nix run '.?submodules=1#pi-task' -- open ../shinyflakes.worktrees/auth-cleanup

# After activation:
pi-task
pi-task --repo ~/shinyflakes new auth-cleanup --base HEAD
pi-task open ../shinyflakes.worktrees/auth-cleanup
```

New tasks use `task/<name>` branches and sibling `<main-checkout>.worktrees/<name>`
directories. Committed submodules initialize recursively. Existing dirty edits
are not copied into new tasks. Request/session/tab attachment metadata lives in
Git's common directory under `pi-task/`, not in tracked source. Reopening focuses
an existing tab or starts an idle agent; it never replays the original request.

Task panes share immutable `PI_TASK_ROOT`. Guardian resolves editor membership
from the live task tab on each review, handles changed editor cwd and restart,
and never falls back to another task's editor. Missing task editor uses existing
standalone review fallback. New agents load updated extension code; existing Pi
sessions need `/reload`.

Guardian IPC directories are runtime-owned, so startup/shutdown cannot erase
another instance's pending review. Guided review also preserves agent-authored
literal annotation-marker text instead of stripping it as human feedback.

Home Manager explicitly uses the existing Zellij fork input, matching launcher
runtime and fork-only bindings. Use that fork for live validation, not upstream
Zellij, which rejects the generated configuration.

Validated:

- `python3 packages/tests/pi-task.py`: real Git isolation, quoting, safe failure,
  reopening without prompt replay, persistence, recursive submodule initialization.
- `python3 packages/tests/pi-task.py --live` with fork on PATH: disposable actual
  Zellij session/client, two task tabs, generated layouts, request arguments,
  deduplicated attachment, actual Neovim sockets and task-bound routing. Pi is
  replaced by a recorder; no model requests are made.
- Guardian tests: 195 passing, including editor restart/movement, task root
  selection, cross-instance IPC cleanup, and literal marker preservation.
- Biome checks from guardian directory, ShellCheck, and Nix formatting checks.
- Package build with `nix build --offline --builders '' --no-link
  '.?submodules=1#pi-task'`; local/offline build avoids stalled normal scheduling.
- Evaluated carryall Home Manager hotkey configuration; validated it with the
  fork's `setup --check` and verified Home Manager selects the fork package.

### 2. Autonomous checkpoint review

#### Implemented: review-state foundations

`packages/pi-task-state.sh` uses existing Bash, Git, jq, and flock dependencies;
no new runtime is required. New tasks initialize state before Pi starts. Existing
worktrees, including stage-1 tasks, adopt a baseline on their first reopen with
the updated launcher; historical task beginnings are not inferred retroactively.

```bash
# Existing edits: choose one, explicitly, on first adoption.
pi-task open ../shinyflakes.worktrees/auth-cleanup --adopt include
# Alternative: trust existing edits instead of including them in first review.
pi-task open ../shinyflakes.worktrees/auth-cleanup --adopt trust

# Save policy without resetting either baseline; reopen without flag preserves it.
pi-task open ../shinyflakes.worktrees/auth-cleanup --review-mode guided
pi-task state ../shinyflakes.worktrees/auth-cleanup
```

Interactive dirty adoption asks include/trust; non-interactive calls require
`--adopt`. Include uses HEAD as starting/accepted baseline. Trust uses current
contents, which may differ from HEAD. Both retain original HEAD, status, and
pre-existing content snapshot as provenance. Re-adoption cannot reset baselines.

Review JSON lives in Git's common directory at `pi-task/reviews/<task-id>.json`.
Task panes receive its path as `PI_TASK_REVIEW_STATE`, alongside `PI_TASK_ROOT`.
Guardian consumes saved policy on each gate; `autonomous` skips per-edit review
but does not bypass safety approvals. Existing panes without the state-path
variable resolve it from immutable `PI_TASK_ROOT`; no pane restart or re-adoption
is required solely to inject that variable.

Snapshots use temporary indexes, preserving real staging/index contents, and
private `refs/pi-task/<task-id>/...` refs keep their trees alive through Git GC.
Each snapshot stores a root tree plus recursive initialized-submodule snapshots;
uninitialized submodules are explicit `null` entries, with gitlinks retained in
the parent tree. Normal untracked files, additions/deletions/renames, binaries,
symlinks, and explicitly staged ignored files are included. Ignored untracked
files are excluded. Unmerged or sparse/skip-worktree indexes fail closed.
Snapshots are local Git objects, not encrypted archives. Keep sensitive untracked
files ignored before adoption. Do not push `refs/pi-task/` (including via mirror
pushes); changing ignore rules later does not erase previously stored contents.

The internal acceptance primitive requires the reviewed snapshot to match
current contents, including nested submodules. It advances only accepted state,
never the starting baseline or provenance. Accepted human edits are included in
that snapshot. Commits, policy changes, and reopening do not advance checkpoints.
Guided per-edit acceptance does not invoke this primitive. Checkpoint gates
below pause cooperating writers before snapshot/review/acceptance; metadata
locks alone do not protect against unrelated processes.

Validated with `bash packages/tests/pi-task-state.sh`: clean/include/trust
adoption, policy persistence, staging preservation (including split indexes),
commit-independent baselines, accepted human edits, stale-snapshot rejection,
isolated worktrees, nested dirty submodules, GC retention, unusual paths,
binaries/symlinks, concurrent initialization, conflict refusal, failed lock/write
preservation, corrupt-state refusal, and read-only launcher inspection. Existing
launcher checks (including native Zellij/Neovim smoke), 195 Guardian tests,
ShellCheck, Nix formatting, and package build remain passing.

#### Implemented: checkpoint gates and minimal batch review

- `/review` creates or reopens a checkpoint in task Neovim. Agent tool
  `request_review({ summary, checks })` requests a checkpoint and ends its run.
  `agent_before_settle` supplies the end-of-run fallback when autonomous tasks
  still have unreviewed changes. No changes means no pending checkpoint.
- Agent/end-of-run requests mark pending and notify without switching focus;
  human explicitly opens `/review`. Saved pending state survives reopening,
  policy changes, `/reload`, and Pi restart. Startup never resumes model work.
- Pending is persisted **before** snapshotting. Shared `flock` leases cover
  cooperating writer tools, including bash and nested codemode calls. Existing
  writes finish before snapshot; new writers are blocked task-wide. Writers
  remain concurrent outside review; no scheduler or single-writer lock exists.
  Same-task children must inherit `PI_TASK_ROOT` and load Guardian. Unrelated
  processes, direct filesystem access in custom orchestrators, and detached
  background writers are not protected; do not launch background writers.
- Reviewer lease prevents two cooperating Pi instances opening competing UIs.
  Failures keep pending state. Runtime IPC remains instance-owned. Missing or
  outdated Neovim plugin cannot silently grant acceptance; editor must
  acknowledge opening the patch before acceptance is offered.
- Batch tab shows the complete unified diff since accepted baseline, including
  shell/committed changes, recursive dirty submodules, additions/deletions,
  renames, symlinks, and binary identification. It does not reuse guided file
  rollback or annotation stripping. Summary/check report comes from agent;
  manual/fallback checkpoints explicitly refer to conversation when absent.
- `ga` accepts; `gx` requests changes without rollback; `gq` or closing tab
  preserves pending and pause. TUI offers equivalent actions. Acceptance
  advances only accepted baseline and unpauses writers; already-idle agents
  remain idle until prompted. Request changes sends a generic revision message
  to the reviewing Pi; dedicated feedback/coordinator routing remains stage 3.
- Save human source edits, then reopen `/review` so updated contents appear in
  patch. Changes made after opening fail acceptance rather than silently enter
  accepted baseline. Batch scratch buffer never overwrites source buffers.
- Task `/guardian` reports saved policy instead of enabling `yolo`. Destructive
  commands keep independent approvals; headless calls requiring approval fail
  closed. Sensitive-path checks apply to direct paths and existing bash checks.

Activate rebuilt `pi-task` and `pi-guardian-nvim` (Home Manager), restart editor
or add updated plugin to runtimepath, then `/reload` Pi before manual smoke.
Existing running children must also reload before relying on cooperative pause.

Validated:

```bash
bash packages/tests/pi-task-state.sh
python3 packages/tests/pi-task.py
node --experimental-strip-types --test modules/aspects/agents/pi/extensions/tool-guardian/tests/*.test.ts
nvim --headless -u NONE -l packages/tests/pi-guardian-batch.lua
nix build --offline --builders '' --no-link '.?submodules=1#pi-task' '.?submodules=1#pi-guardian-nvim'
```

197 Guardian tests pass, including actual TypeScript-to-Neovim IPC and real-Git
Guardian hook integration with concurrent instances/restart recovery. Native Pi
RPC startup checked with clean and pending state, without model requests. Biome
from Guardian directory and ShellCheck also pass. Manual checkpoint smoke is
still required; native stage-1 workspace smoke was verified earlier.

#### Remaining

Changed-file list/side-by-side navigation, original request presentation,
whole-task/checkpoint scope toggle, hunk/file revert, and pending-review picker
routing. Then dedicated feedback/drafts/coordinator routing and delegation skill.

### 3. Annotation and revision loop

Add dedicated inline/task comments, questions, persisted drafts, direct-edit
feedback, and coordinator submission. Add a delegation skill describing child
agent conventions instead of a child-agent orchestration subsystem.

Check: submit comments plus direct edits, revise again, retain unresolved or
outdated comments, revert hunk/file without resuming, and recover pending review
following Pi restart.

### Integration points for the next slice

- `packages/pi-task.sh` and `packages/pi-task.nix`: task launch, attachment,
  metadata, and task layout; `packages/tests/pi-task.py` contains launcher checks.
- `packages/pi-task-state.sh`: saved policy, adoption provenance, Git snapshots,
  and acceptance primitive; `packages/tests/pi-task-state.sh` contains real-Git
  regression checks. Consume `PI_TASK_REVIEW_STATE` with a task-root-based lookup
  fallback for already attached panes that predate the variable.
- `modules/aspects/shell/zellij.nix`: package selection and navigation bindings.
- `packages/pi-herd.sh` and `packages/pi-herd.nix`: existing instance picker.
- `modules/aspects/agents/pi/extensions/tool-guardian/`: policy, review hooks,
  editor routing, notifications, and status publication.
- `packages/pi-guardian-nvim/`: current Neovim review UI and response handling.
- Existing packaging and agent skills; reuse rather than add parallel systems.

Stage 1 addressed IPC ownership and live editor routing. Checkpoint slice adds
a separate no-rollback batch boundary and explicit sensitive-path/command gate
coverage, independent of `yolo`. Keep these regressions passing while expanding
UI/navigation, and keep runtime IPC separate from durable review state.

## Explicit follow-ups

### Small-model review guidance

After isolation and the review loop work, explore advisory prioritization:

- **Risk hotspots:** correctness and security-sensitive changes.
- **Understanding hotspots:** unfamiliar behavior and architectural decisions
  worth learning.

Keep these separate rankings. A small model may suggest an earlier review
checkpoint, but must not silently change review policy, grant permissions, hide
unhighlighted changes, or replace explicit safety gates. First version uses the
implementing agent's concise rationale and check report without this dependency.

### Other follow-ups

- Claude integration with the same worktree/workspace and feedback model.
- True pre-write guided gate if preventing disk mutation before approval is
  required.

## Intentionally not built

No shared-editor retargeting, separate dashboard, enforced child-agent writer
scheduler, automatic merge/deploy, automatic worktree deletion, whole-batch
revert, or custom cursor/layout restoration.
