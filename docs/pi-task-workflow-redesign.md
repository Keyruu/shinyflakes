# Pi task workflow redesign

Status: Step 1 reliable resume and its correction pass are implemented and checked
in source; coordinator inspection remains. No activation or live user-task smoke
has occurred. TypeScript migration and Steps 2–3 remain proposals, not authority
to launch commands or change running sessions. [Current workflow](worktree-review-workflow.md)
is the operational reference; proposed commands beyond `resume` remain unimplemented.

## Implementation status

### Step 1: reliable resume — source complete, not activated

- `packages/pi-task.sh` adds `resume`: focus verified live coordinator, restore
  missing Pi beside surviving editor/shell, or recreate missing task tab using
  exact native `pi --session`. Original request is delivered only on initial
  launch. `open` navigates existing workspaces; first-time worktree adoption
  retains legacy behavior. Launch lock and uncertain-launch marker prevent
  duplicate recovery; the twentieth visibility poll counts as success.
- `packages/pi-task-state.sh` and Guardian persist the coordinator's session
  ID/file without resetting fixed review base, draft, pending feedback or
  ownership. Bind and resume share transcript-header validation: Pi sessions
  started in a subdirectory of the same Git worktree are accepted; sessions
  from another checkout are rejected.
- Guardian publishes active session ID/file in its existing per-process herd
  record and clears it before native session switches. Launcher checks that
  live record against the task and Zellij pane, not the original Pi launch
  command. Missing, stale or switched identity fails closed without focusing
  wrong conversation or launching a duplicate. Coordinator transfer and saved
  feedback retry remain explicit.
- Missing transcript/locator or uncertain first delivery offers explicit
  session-picker/fresh-conversation recovery; navigation never replays request,
  feedback or a model turn.

Focused regressions cover workspace recovery, concurrent resume, changed or
missing identity, allowed subdirectory and rejected checkout, final-poll success
and genuine timeout. Checks completed:

```bash
bash -n packages/pi-task.sh packages/pi-task-state.sh packages/tests/pi-task-resume.sh
bash packages/tests/pi-task-resume.sh
node --experimental-strip-types --test modules/aspects/agents/pi/extensions/tool-guardian/tests/*.test.ts
nix build --offline --builders '' --no-link '.?submodules=1#pi-task'
git diff --check
git -C modules/aspects/agents diff --check
```

All commands above passed. Guardian: 233 passed, one optional Neovim test
skipped. Isolated native Pi RPC probe confirmed exact subdirectory transcript
resumes from worktree root and `session_before_switch` precedes new
`session_start`; Guardian tests cover identity invalidation. No prompt sent.
No installed-package activation, deployment,
or destructive smoke against running task. Updated Guardian must be active before
live identity checks can recognize an existing Pi; older runtimes fail closed.

### Suggested next slices (separate approval required)

1. **TypeScript/shared-core migration:** propose a bounded file-level plan for
   the [shared core and packaging](#implementation-language-and-shared-core).
   Preserve Step 1 behavior and tests; keep `pi-task` as a
   `pkgs.writeShellApplication` with Node and required tools in `runtimeInputs`.
   This migration is documented, not yet authorized for implementation. Ask for
   approval before starting; do not combine it with a functional redesign.
2. **Step 2: same-window startup:** reuse the current client/terminal instead of
   forcing footclient; use its acceptance criteria below.
3. **Step 3: main-checkout tasks:** independent task identity, `--here`, separate
   review lifecycles, and picker improvements; use its acceptance criteria below.

The suggested order is not permission to execute every slice. Confirm the next
slice with the user, run one worker at a time, and stop after the authorized
slice. Do not launch a second worker merely because this handoff exists.

### Preserve existing work

Both the parent repository and agents/private submodules have unrelated dirty
changes. Inspect status in each relevant repository, reread before editing, and
preserve saved changes. Do not reset, clean, auto-commit, copy patches over files,
change branches, or create a worktree to bypass the shared-checkout decision.

The coordinator added the TypeScript/Node/Nix design and the Zellij skill after
the worker's original implementation. Preserve them. The skill is
`modules/aspects/agents/skills/zellij/SKILL.md`, referenced from
`modules/aspects/agents/pi/AGENTS.md`; existing symlinks expose it to new Pi
sessions without a rebuild. Register new submodule files in that submodule for
review, not merely in the parent index. Source changes do not update the installed
`pi-task`; test the rebuilt package before claiming installed behavior changed.

## Goal

Make three actions straightforward: **work here**, **isolate this**, and
**continue that**. Keep Pi, Zellij, Git, and Neovim; do not build an Orca clone,
new daemon, custom transcript store, or replacement editor.

Before Step 1, launcher coupled task identity, checkout path, review state, and
Zellij tab. Isolated tasks were convenient but recovery was rigid:

- `new` always creates a branch and linked worktree.
- `open` initializes or validates review state and rejects a new request.
- Task and review records are keyed by checkout path, preventing separate task
  lifecycles in the same checkout.
- Recreating a tab launched fresh Pi with original request, not saved
  conversation; previous review coordinator could remain bound.
- A surviving editor or shell could satisfy tab discovery even when Pi was gone.
- A missing or detached repository session forces a footclient window.

These findings come from `packages/pi-task.sh`, `packages/pi-task-state.sh`,
`modules/aspects/agents/pi/extensions/tool-guardian/task-review.ts`, and
`modules/aspects/agents/pi/extensions/tool-guardian/batch-feedback.ts`.

## Separate the concepts

| Concept | Owns |
| --- | --- |
| Checkout | Files and Git branch; main checkout or linked worktree |
| Task | Request, title, fixed review base, coordinator/session reference |
| Pi session | Conversation history |
| Workspace | Live editor, shell, and agent panes |
| Presentation | The terminal window, Zellij session, and tab displaying work |

Invariants:

- A checkout can host successive tasks with separate identities and reviews.
- A task has a stable ID independent of its checkout path and remains bound to
  its chosen checkout. Changing shell cwd does not move the task.
- Closing panes does not finish a task or delete files.
- Opening a workspace does not submit prompts.
- Resuming a conversation does not repeat its original request.
- Main checkout and main branch are different concepts. Starting here uses the
  current checkout and checked-out branch; it never silently switches branches.
- Separate task IDs do not isolate files. Concurrent writers in one checkout
  can interfere, and their diffs can overlap.

## Everyday workflows

### Start here

```bash
pi-task new fix-config --here --request 'Fix configuration'
```

Use the current checkout, including main. Create a task identity, capture a
committed review base, and start Pi in the existing terminal context. Deliver
the initial request once. Preserve the branch, dirty files, and existing editor.
No new worktree, Zellij session, or footclient window is required.

Ordinary Pi remains a lightweight alternative: `/new`, `/resume`, and `/review`
do not require named task registration. A later thin Pi extension entry point
can bind a named task inside the current Pi process. It must explicitly update
its task context rather than pretend that changing a shell environment rebinds
an already-running agent. Native `/new` inside a tracked task must not silently
steal its coordinator or turn a different task into the old task's review.

### Start an isolated task

```bash
pi-task new auth-cleanup --request 'Refactor auth validation'
```

Keep the existing CLI default for compatibility: create a linked worktree and
`task/<name>` branch from a committed base, initialize committed submodules,
and open its workspace in the current window by default. Do not copy dirty
main-checkout edits. The interactive picker makes the isolation choice explicit.

### Return to existing work

```bash
pi-task open /path/to/checkout
pi-task resume auth-cleanup
```

| Command | Meaning |
| --- | --- |
| `open PATH` | Navigate to a workspace without starting a task or sending a prompt |
| `resume TASK` | Focus the live coordinator or restore its exact saved conversation |

An explicit target path determines the repository unless `--repo` is supplied.
A conflicting `--repo` must produce a clear error. Unregistered worktrees can
open without choosing a review baseline or adopting dirty files. Starting a
tracked task is a separate operation.

Task IDs are unambiguous selectors. Names resolve within the selected repository;
ambiguous names require a picker, not an arbitrary match.

## Resume contract

| Actual state | Required behavior |
| --- | --- |
| Coordinator Pi alive | Focus it without sending a message |
| Editor/shell alive, Pi gone | Keep the layout and restore only Pi |
| Workspace gone, transcript exists | Recreate presentation and resume the exact transcript |
| Transcript missing | Explain and offer a session picker or explicit fresh conversation |
| Multiple tasks in checkout | Select the task rather than guessing the latest conversation |
| Saved feedback pending | Preserve it without automatic replay |

Persist the exact Pi session locator when the coordinator binds or explicitly
changes. Use native `pi --session`; do not use bare `--continue` for task
recovery, because another conversation may be newer in the same checkout.
Validate live instance identity before launching a replacement to avoid duplicate
coordinators on repeated or concurrent resume requests.

The original request remains metadata. Automatic delivery is only for a genuinely
new task launch, never recovery. If failure makes initial delivery uncertain,
show that uncertainty instead of silently resending. Do not claim exactly-once
delivery based solely on successful pane creation.

Restore the same coordinator session where possible. A different session taking
ownership requires explicit transfer. Preserve existing protection against child
sessions stealing review ownership. Opening or resuming must not retry saved
feedback or trigger a model turn merely to explain recovery.

## Window and session contract

Default: reuse the caller's window. Open a new window only when requested or when
there is no usable terminal, such as a desktop-launcher invocation.

| Invocation context | Default |
| --- | --- |
| Inside Zellij | Reuse the current client; focus a workspace or create a task tab |
| Plain interactive terminal | Run or attach in that terminal |
| Existing Pi | Keep its conversation unless explicitly switching; additional work uses a separate pane/tab |
| Desktop launcher without a terminal | Open the configured terminal window |
| Noninteractive automation | Require an explicit presentation choice; do not silently spawn a GUI |

Two presentation overrides are sufficient initially:

```bash
pi-task new fix-config --here --tab
pi-task resume auth-cleanup --window
```

Repository Zellij sessions can remain. Reuse the current-client switch/create
approach in `packages/zs.sh` instead of implementing another session manager.
Retain client-readiness protection: replacing mandatory footclient must not
reintroduce unreliable headless pane creation.

A full editor/shell/Pi layout is a convenient default, not a prerequisite to
start a conversation. Navigation and presentation must remain separate from
prompt delivery. Automation that is not an explicit user navigation request
should preserve focus.

## Review and dirty checkout rules

- Fixed committed base belongs to each tracked task, not permanently to a
  directory.
- Opening a dirty checkout does not require adoption.
- Starting a tracked task there discloses existing edits and requires explicit
  inclusion, using the existing adoption semantics.
- Review covers changes against the chosen base, not claimed agent authorship.
- Finishing a review does not commit, reset, clean, switch branches, or finish
  other tasks in that checkout.
- A subsequent task gets a separate identity and base while previous review
  history remains intact.
- Ordinary Pi review retains its existing session-scoped behavior.

Warn when another known agent is active in the shared checkout and offer an
isolated worktree. This is advisory, not proof that no other writer exists.
Do not add writer locks or pretend that separate metadata provides file or diff
isolation. Keep sensitive-file and destructive/external-action safety gates.

## Picker

Use one entry point for task intent and recovery:

```text
Start here…
New isolated task…
────────────────────────
Auth cleanup       waiting       linked worktree
Fix configuration  agent closed  main checkout
Review deployment  running       main checkout
────────────────────────
Open checkout…
```

Show title, checkout, pending review, and agent state separately from workspace
state. Include last activity where already available. Open, Resume, and New
conversation are distinct actions.

Reuse Git worktree discovery, saved Pi session references, and live-instance
information. Do not create a separate global workspace database.

## State and compatibility

Minimum durable additions are a stable task ID and exact coordinator session
locator, alongside the existing checkout, request, model, and review metadata.
Pane and tab IDs remain disposable attachment hints, validated against live
bindings before reuse.

- Existing tasks retain their fixed base, notes, submissions, request, and model.
- Existing path-derived identifiers can remain legacy task IDs; do not rename
  branches or worktree directories.
- Missing session references require explicit recovery, not prompt replay.
- No bulk rewrite or automatic cleanup of old tasks.
- Repository session identity must avoid collisions between equal basenames;
  readable display titles need not carry that identity.
- Reconcile the `Alt-T` launcher's `close_on_exit true` setting in
  `modules/aspects/shell/zellij.nix` with the documented prohibition against
  killing task panes when the launcher exits. Verify the actual lifecycle.

## Implementation language and shared core

Proposed follow-up: move launcher/state application logic to TypeScript after
reliable resume is complete and before expanding independent task identity.
This is not part of the completed Step 1 slice and is not implemented yet.
Keep the public `pi-task` CLI and Nix package; a language change must preserve
existing behavior and recovery guarantees rather than rewrite the lifecycle
and implementation simultaneously.

TypeScript is preferred because Guardian already uses it: the benefit is one
executable state contract, not types alone. Bash remains suitable for small
wrappers. Python would be reasonable for an independent launcher, but would
retain a second implementation of the contract consumed by Guardian.

### One source of truth

Keep shared code inside the agents submodule so it does not depend on parent
repository source. Proposed layout:

```text
modules/aspects/agents/pi/
├── lib/task-state.ts
├── cli/pi-task.ts
└── extensions/tool-guardian/task-review.ts
```

Both CLI and Guardian import `lib/task-state.ts`. Share state types, runtime
validation of saved JSON, state-path calculation, reading, compatibility checks,
and state-transition rules. Do not share only interfaces while duplicating the
actual validation. Zellij discovery/launch and argument parsing stay in the CLI;
Guardian hooks, notifications, and editor integration stay in the extension.

Initially keep one mutation authority: Guardian imports the shared reader and
validator but continues invoking `pi-task` for writes. The CLI locks, validates,
updates, and atomically saves state. Preserve cross-process locking; atomic
replacement alone does not prevent lost updates. Do not introduce a second
writer implementation or change locking semantics merely because the language
changed. Direct shared mutation calls are a later option only if subprocess
cost justifies them.

Shared source does not guarantee matching running versions. Guardian loads live
source while the installed Nix CLI can lag. Maintain format compatibility and
clear errors for unsupported state versions; test packaged CLI/Guardian
compatibility before activation.

### Execution and packaging

Run TypeScript with a Nix-pinned Node version supporting native type stripping.
No `tsx`, `ts-node`, bundler, compilation step, or global Node install is needed.
Use erasable TypeScript with explicit relative `.ts` imports; avoid enums,
constructor parameter properties, and TypeScript-only path aliases. Keep ESM
interpretation explicit in the packaged source, for example through a minimal
`package.json` with `"type": "module"`.

Keep `packages/pi-task.nix` as a `pkgs.writeShellApplication`. Declare Node and
all required external commands in `runtimeInputs`; let the generated wrapper
supply `PATH`, rather than requiring a global Node install or manually assembling
a shell search path. Package the CLI and shared library together, preserving
`cli/`, `lib/`, and the ESM `package.json`. Copy only required runtime source,
not the whole agents configuration.

With `source` pointing to that filtered Nix source tree, the wrapper has this
shape:

```nix
pkgs.writeShellApplication {
  name = "pi-task";
  runtimeInputs = with pkgs; [
    nodejs
    git
    zellij
    jq
    fzf
    zoxide
    coreutils
    gawk
    gnugrep
    util-linux
  ];
  text = ''
    exec node --experimental-strip-types "${source}/cli/pi-task.ts" "$@"
  '';
}
```

Retain existing CLI dependencies while the port still invokes them; remove
individual inputs only when their uses disappear. Node comes from the pinned
Nix package set and must support the selected type-stripping mode. `exec`
preserves normal signal handling and exit status. Mutable task/session data
stays in existing state locations, never alongside source in the store.

Callers keep using `pi-task`: humans, Zellij keybindings, and Guardian's
`execFile("pi-task", args)` do not need a new invocation protocol. Development
can execute the future source directly:

```bash
node --experimental-strip-types modules/aspects/agents/pi/cli/pi-task.ts --help
```

Migration acceptance: existing resume/state tests still pass; corrupt and legacy
state use the same validation in both consumers; the Nix-packaged command works
outside the source checkout with intact imports and no global Node dependency.
Keep focused failure/recovery tests. Type checking cannot prove a process is
alive or an external launch succeeded.

## Agent-directed Zellij commands

Agents should use visible, named command panes for long-running builds, tests,
dev servers, and log followers when the requested work calls for them. This is
an instruction-level capability using native Zellij, not a new process manager.
Short commands still belong in the ordinary shell tool.

### Permissions and targeting

- Stay within the current task/workspace. Verify the session, tab, and pane
  binding; never infer ownership from a title, screen position, or current cwd
  alone. Revalidate targets after reconnect or session restart.
- Use explicit session and pane/tab IDs. Do not send input to whichever terminal
  happens to be focused or navigate by repeated focus-left/focus-down actions.
- Use `--no-focus` for new command panes. Do not steal focus, switch sessions,
  rearrange existing panes, or replace editors/agents without permission.
- Reuse a bottom terminal only when it is task-owned, known idle, and has no
  pending human input. A prompt-shaped screen or original shell launch command
  is not proof of idleness. If uncertain, create a separate named pane; ask
  before taking over a human-owned terminal.
- Never overwrite shell input, send Ctrl-C, close a pane/tab, or stop a process
  without permission. Creating a command pane does not authorize deployment,
  deletion, network exposure, secret access, or other sensitive actions.
- Prefer launching a command directly over injecting shell text. Avoid secrets
  in command arguments, titles, or screen dumps. Inspect only relevant panes and
  output, respecting existing sensitive-data rules.

### Verified CLI building blocks

Checked against the installed Zellij fork reporting `zellij 0.46.0`, using
`zellij action <command> --help`. These flags are not a promise about stock or
older Zellij releases; verify help before use elsewhere. The examples assume
`session`, `tab`, and `root` are already resolved and validated for the task.
`bottom_pane` is an explicitly verified idle task-owned shell pane.

Inspect panes and choose targets without changing focus:

```bash
zellij --session "$session" action list-panes --json --all
```

Launch a named long-running command without taking focus. Here the command is a
Pi package build; substitute the command authorized by the actual task:

```bash
pane=$(zellij --session "$session" action new-pane \
  --tab-id "$tab" --no-focus --direction down --cwd "$root" \
  --name 'build: pi-task' -- nix build '.?submodules=1#pi-task')
```

`new-pane` returns a pane ID such as `terminal_12`. Capture and validate it, then
confirm the pane belongs to the intended tab and command. `--direction down`
does not identify the existing bottom terminal: the new pane is positioned
relative to the issuing pane when using `--no-focus`.

Where bottom-shell reuse is authorized and verified, use an in-place command
rather than typing into the shell:

```bash
pane=$(zellij --session "$session" action new-pane \
  --in-place --pane-id "$bottom_pane" --no-focus --cwd "$root" \
  --name 'build: pi-task' -- nix build '.?submodules=1#pi-task')
```

The documented in-place behavior temporarily suspends the replaced pane.
Do not pass `--close-replaced-pane`, which destroys it. Do not use
`--close-on-exit`: preserve completion output for inspection. Restoring or
closing panes must follow the permission rule above; exact focus and restoration
behavior still needs a live smoke test before this becomes an agent default.

Read output from the returned command pane without focusing it:

```bash
zellij --session "$session" action dump-screen --pane-id "$pane"
zellij --session "$session" action list-panes --json --all
```

`dump-screen --full` includes scrollback; use only when needed because output may
be large or sensitive. Targeted `write-chars --pane-id` and `send-keys --pane-id`
exist, but are not the default for launching jobs. Sending text and Enter is not
atomic with an idle check and may affect a newly busy shell or pending human
input.

### Lifecycle and reporting

- Check whether the intended job already exists before launching another.
- Keep the command in its managed pane; avoid `nohup`, trailing `&`, or extra
  daemons merely to escape tool timeouts.
- Record the returned pane ID, command, cwd, and purpose in task/conversation
  context. No additional persistent job registry is required initially.
- Inspect at meaningful milestones, not through rapid unbounded polling.
- Pane creation is not success of the command. Distinguish running, completed,
  failed, and unknown; report an exit status only when actually observed.
- Report still-running jobs and their panes at task completion. Do not silently
  stop them, relaunch them after reconnect, or close their output.
- Closing the task UI is not permission to kill jobs. Host/session loss does not
  imply that a process survived; inspect before claiming recovery.

Operational instructions now live in
`modules/aspects/agents/skills/zellij/SKILL.md`, referenced from `pi/AGENTS.md`.
The first sequential Pi worker was launched and verified in the current tab.
That smoke test showed stacked creation can change the visible stack member
despite `--no-focus`; the skill records this caveat. Bottom-shell restoration
still needs a separate live test. This spec alone does not activate launcher
changes.

## Delivery order and acceptance criteria

### Step 1: reliable resume (implemented in source; no live user-task smoke)

- Closing only Pi restores the same conversation beside the surviving editor.
- Closing the workspace restores the same conversation in a recreated layout.
- Repeated or concurrent resume does not duplicate Pi or the initial prompt.
- Missing transcripts produce explicit recovery choices.
- Review feedback still targets the correct coordinator.

### Step 2: same-window startup

- A missing repository session starts through the current Zellij client.
- A detached session attaches without an extra footclient.
- A plain terminal works without footclient installed.
- `--window` deliberately opens a window.
- Repositories with identical basenames remain distinct.
- Picker exit does not kill launched task panes.

### Step 3: main-checkout tasks

- Two successive tasks share a checkout but retain separate sessions and bases.
- Dirty-file inclusion is explicit and preserves existing files.
- External worktrees open without adoption.
- Explicit cross-repository paths work from any cwd.
- Ordinary Pi `/new` and `/review` remain usable without task registration.

### Zellij instruction rollout

This can proceed independently after the permissions contract is accepted:

- A long-running command starts in the intended tab without moving user focus.
- Output can be read through the returned pane ID without focusing it.
- A busy shell or pending human input is never touched; a separate pane is used.
- Authorized in-place reuse preserves the original idle bottom shell and verifies
  its restoration behavior, including when the command exits with an error.
- Stale pane IDs and restarted sessions are rejected rather than targeting
  unrelated panes.
- Command failure and still-running jobs are reported accurately; no automatic
  interruption or cleanup occurs.

## Non-goals

Automatic branch switching, worktree deletion, merges, deployment, a scheduler,
custom transcript storage, full Orca-style workspace restoration, and a generic
layout/backend configuration system are excluded. Existing Git/review safeguards
and explicit human decisions remain.

## Comparison sources and validation

Orca informed the separation of workspace creation, agent launch, and session
resume, not a proposal to copy its architecture. Sources reviewed at commit
`6d473f4bea1d190cb3649af97e04f1cdde170c5f`:

- [Existing-workspace agent launch](https://github.com/stablyai/orca/blob/6d473f4bea1d190cb3649af97e04f1cdde170c5f/src/cli/handlers/agent-launch.ts)
- [Agent session history](https://github.com/stablyai/orca/blob/6d473f4bea1d190cb3649af97e04f1cdde170c5f/docs/site/content/docs/agents/session-history.mdx)
- [Session restore and its limits](https://github.com/stablyai/orca/blob/6d473f4bea1d190cb3649af97e04f1cdde170c5f/docs/site/content/docs/model/session-restore.mdx)
- [Workspaces and external worktrees](https://github.com/stablyai/orca/blob/6d473f4bea1d190cb3649af97e04f1cdde170c5f/docs/site/content/docs/model/worktrees.mdx)

The initial comparison used local launcher/review source and installed Pi/Zellij
CLI help; launcher shell syntax checks passed. Subsequent stacked-worker startup
and targeted output inspection were verified live as described above. Step 1
implementation checks are recorded in the current workflow document; broader
live recovery, bottom-shell restoration, and proposed migration acceptance
checks remain distinct from those results.
