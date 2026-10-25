# Pi task workflow redesign

Status: **Steps 1–2 accepted. Bounded Step 3 native smoke passed after Pi-stack and Guardian lifecycle fixes. User activated; installed runtime verified October 25.**
October 24's approved disposable smoke verified Pi stacking, independent task
identities/bases, dirty-file inclusion, external-worktree navigation and native
`/new` → `/reload` → ordinary HEAD-based `/review`. Coverage limits and the test
isolation incident are recorded below. Steps 1–2 remain closed:
user confirmed corrected layout and explicitly closed further testing. Remaining
untested cases are waived for this handoff, not claimed as passed. No additional
recovery/startup smoke is required before proceeding. This decision supersedes
earlier stop-before-Step-3 and further-smoke instructions recorded below.

Steps 1–2 and TypeScript/shared-core migration are implemented and pass
source checks. **Step 2's current-terminal workflow passed live validation:**
user-operated picker → new task tab → picker exit → reopen/resume, with the same
editor/Pi/shell surviving and no duplicates. Plain-terminal startup, explicit
`--window`, environment forwarding, launch-lock release and attached-target
refusal also passed. Earlier cross-repository creation passed, but return from
its cold destination failed on the older installed fork. The native-fork debug
build subsequently passed cold navigation. A later startup race blocked packaged
integration on October 23. **October 24's new installed build passed shell-only
startup, the real project layout, and `pi-task new --window` with startup polling
and user-confirmed responsive input.** Follow-up packaged launcher smoke passed
same-window cross-repository creation, `open` return, `resume` into the detached
destination and attached-target refusal, with unchanged task panes/coordinators
and no extra window. Recovery preparation exposed a Guardian socket-ID/name
bug; **native CLI name discovery now fixes it, with regression coverage and a
successful missing-Pi recovery smoke.** Only the disposable Pi was reloaded, then
closed and restored with the same UUID, byte-identical transcript and review
state; editor/shell processes survived. User then caught incorrect geometry:
generic pane insertion left a full-width bottom shell. **Rebuilt launcher now
reapplies the standard layout with native pane reuse; repeated recovery passed
exact rectangle, survivor-PID, transcript and review checks.** This layout fix
was subsequently activated by the user, as verified below. Full-workspace native recovery remains untested and is
waived as a progression gate by user. That Steps 1–2 coordinator performed no
system activation or Step 3 implementation. The subsequent approved Step 3
implementation is recorded below.
[Current workflow](worktree-review-workflow.md) is the operational reference.

## Activation — 2026-10-25: installed runtime verified

User reported completing the switch and reloading this coordinator. Read-only
checks on `lucas-rott-linux` confirmed:

- Installed `pi-task` resolves to
  `/nix/store/rc1dfkh95kg6ang0j0miqr2h8z88y50x-pi-task/bin/pi-task`.
  Packaged `cli/{pi-task,review,runtime}.ts`, `lib/task-state.ts` and `package.json`
  match current checkout byte-for-byte; wrapper pins Zellij `261h2bi…`.
- Home Manager's `~/.pi/agent/lib` and
  `~/.pi/agent/extensions/tool-guardian` links resolve to the current agents
  submodule source, including the Guardian replacement-lifecycle fix.
- Current Guardian herd record matches conversation
  `01a17250-09b9-74cb-a245-b261ab538903`, its transcript locator and
  `shinyflakes:terminal_1`. No task binding is present in this ordinary session.
- Installed `pi-task --help` and parent/agents `git diff --check` passed.
  Regression suites and native smoke were not repeated; prior coverage limits
  remain unchanged. Activation command/profile was not observed by this agent.

No further implementation or activation step remains in this plan. No extra Pi
was needed; this verification did not reload other Pis, restart Zellij, navigate
workspaces or alter task/review state. Older running Pis still require explicit
selection before reload.

Disposable-fixture cleanup was subsequently authorized and completed below.
Smoke window/review bindings are historical. Do not reopen Steps 1–2 validation
or repeat waived smoke. Native picker/shared-recovery coverage limits remain
recorded below. No isolated project task worktree was created for this implementation.

- [x] Source checks, regression suites and packaged builds completed.
- [x] Startup, switching, attachment and missing-Pi recovery validation completed.
- [x] Standard layout repaired, native geometry/process checks passed, user
  visually confirmed corrected layout.
- [x] Remaining validation closed by user waiver: full-workspace native recovery,
  actual multi-client routing, mixed-version compatibility and optional skipped
  Neovim acknowledgement check. These are not additional passing-test claims.

Step 3 rebuilt launcher with Pi stacking: `/nix/store/rc1dfkh95kg6ang0j0miqr2h8z88y50x-pi-task`.
Initial Step 3 package `rf5v73…` splits the editor area for `--here`; do not use it
for the corrected placement contract.
The earlier Steps 1–2 package was `7rcic2i…`, pinning Zellij `261h2bi…`;
the previously inspected installed `n4xd889…` predates the layout fix. Step 3's
`rc1dfkh…` package is now installed. Rebuild current source if needed. Preserve multi-client
refusal and no-request-replay guarantees;
never retry `new` for an existing task or manually edit task state.

### Disposable-fixture cleanup — 2026-10-25: complete

User explicitly authorized closing verified smoke sessions and deleting all ten
listed temporary fixture directories, including dirty Step 3 test files and
temporary review history, plus the clean Step 2 worktree.

- Revalidated pane commands/cwds, then closed seven live fixture sessions:
  `plain-cb009fbbd665`, `direct-nix-LFmZ83`, `direct-raw-LFmZ83`,
  `zellij-new-smoke-sRd9UQ`, `repo-d5ce4ca3b00e`, `repo-34b59b63b534`, and
  `e25298811144` (the Step 3 fixture's current name). Removed remaining exited
  fixture session records, including `direct-project-LFmZ83` and
  `zellij-project-smoke-kkw3qp`. No fixture processes remained before file removal.
- Deleted the ten documented `/tmp` fixture roots: `pi-task-live-hMCEC4`,
  `zellij-native-cold-2M2Oi6`, `zellij-direct-LFmZ83`, `zellij-new-smoke-sRd9UQ`,
  `zellij-project-smoke-kkw3qp`, `pi-task-new-smoke-o9kxrS`,
  `pi-task-transition-pYR9ny`, `pi-task-step3-0C725P`,
  `pi-task-step3-native-0Aw9hT`, and `zellij-bottom-stack-mIt6cj`.
  Their evidence paths and saved fixture bindings below are now historical,
  not available artifacts or recovery targets.
- Removed `/home/lucas/shinyflakes.worktrees/step2-current-terminal` after
  confirming parent and initialized submodules were clean. Retained its branch
  and main-repository task/review history. Saved Pi transcripts under
  `~/.pi/agent/sessions` were not removed.
- Verified fixture paths/session records absent, real checkout and agents/private
  diffs/status unchanged, and current `shinyflakes` panes/geometry/client focus
  unchanged. Unrelated sessions and `smoke-20261016-155927` worktree remain.
  Cleanup snapshots: `/tmp/pi-task-cleanup-3l5zqgfi`.

## Implementation status

### Step 1: reliable resume — source complete, missing-Pi native recovery passed

- `modules/aspects/agents/pi/cli/pi-task.ts` implements `resume`: focus verified live coordinator, restore
  missing Pi beside surviving editor/shell, or recreate missing task tab using
  exact native `pi --session`. Original request is delivered only on initial
  launch. `open` navigates existing workspaces; first-time worktree adoption
  retains legacy behavior. Launch lock and uncertain-launch marker prevent
  duplicate recovery; the twentieth visibility poll counts as success.
- `modules/aspects/agents/pi/cli/review.ts` and Guardian persist the coordinator's session
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

### TypeScript/shared-core migration — source complete, not activated

- `pi/lib/task-state.ts` owns version-2 types, paths, JSON validation, legacy
  conversion and transitions. Guardian imports its reader/validator and still
  delegates all writes to `pi-task`; `pi-herd` delegates validation there too.
- `pi/cli/pi-task.ts` ports the launcher without changing presentation or task
  identity. `cli/review.ts` owns mutation commands; `cli/runtime.ts` preserves
  existing native `flock` files and private atomic replacement. Locks are not
  inherited by terminal/server commands.
- `packages/pi-task.nix` packages only runtime sources plus ESM `package.json`,
  with Nix-pinned Node and required tools. Parent Bash files are thin
  source-checkout/test adapters, not another implementation.
- Home Manager exposes `~/.pi/agent/lib`: actual Pi resolves relative shared
  imports from installed extension symlinks, not the source checkout.
  **Activate this link before reloading Guardian.** No link was installed by
  this implementation slice.

Checks passed: resume regressions (including initial request/model delivery),
235 Node tests with one optional Neovim test skipped, isolated offline Pi loader
fixture, Bash syntax, Nix formatting for package files, offline `pi-task` and
`pi-herd` builds, and both repositories' `git diff --check`.
Home Manager evaluation for carryall also passed and resolves the new
`home.file.".pi/agent/lib".source`; this verifies configuration only, not activation.
Five focused checks also passed against the Nix-packaged CLI and live-source
Guardian; state operations run outside the source checkout with empty `PATH`.
Lock tests cover old Bash/new Node contention, concurrent writes, independent
reviewer leases and release on process death. Migration checks preserve archive,
drafts, pending review, feedback and dirty source bytes.
Static typechecking and live user-task smoke were not run; optional development
tool bootstrap failed, while native Node stripping/runtime checks passed.

### Step 2: same-window startup — source checked, native validation partial

- `pi/cli/pi-task.ts` switches/creates repository sessions through the current
  Zellij client. Plain terminals run Zellij with inherited terminal I/O, without
  footclient. `--window` explicitly opens footclient; noninteractive invocations
  without a Zellij context must opt in. No desktop/automation guessing.
- New session names combine repository basename with a hash of the canonical
  Git common directory. Existing saved names survive even when sessions vanish;
  task identity, review history and transcript locators are unchanged.
- Client readiness precedes task pane creation. The uncertain-delivery marker
  is set only immediately before launching Pi, not before terminal startup.
  Plain-terminal attachment releases the launch lock before waiting for detach.
- **Approved restriction:** no multi-client navigation. The pinned fork routes
  CLI focus/switch actions to its last-active client, not a specified client.
  The launcher rejects unknown/multiple clients and refuses to add another
  client to an attached destination, including `--window`. Use its sole attached
  terminal or detach manually first. Counts are checked again before launch and
  focus; these observations are not atomic client leases.
- Alt-T's `close_on_exit true` stays unchanged. Source inspection of pinned
  Zellij `0ad1fa042c5284d880ac22c12b9136e174e4f9e0`,
  `zellij-server/src/pty.rs`, verified the exit callback closes the originating
  pane ID, not the newly created task tab. Launcher uses server-created task
  panes, not a nested client in its picker. The subsequent user-operated native
  scratchpad smoke confirmed task panes survive picker exit, as recorded below;
  the blanket instruction claiming all picker exits kill task panes was corrected.

Checks: isolated resume/presentation fixture passed, including PTY attachment,
missing/detached sessions, `--window`, equal basenames, caller validation,
unknown/concurrent clients, readiness timeout, picker exit and preserved review
state. Full Node suite: 235 passed, one optional Neovim test skipped. Offline
`pi-task` build, five packaged-CLI/state/Guardian compatibility tests, Bash syntax
and both repositories' `git diff --check` passed. Static TypeScript checking
and activation were not performed. Native smoke results follow.

#### Native smoke — 2026-10-23: partial pass, cold focus failed

User authorized Step 2 smoke only, explicitly stopping before Step 3. Used
rebuilt package `/nix/store/qp7icykm3pfv3kv3ag96bx958sf6pyqw-pi-task` and native
Zellij 0.46.0 fork, not stubs. The installed `~/.pi/agent/lib` link is missing,
so disposable Pi used `/tmp/pi-task-live-hMCEC4/agent` with source Guardian/shared
library symlinks, isolated cache, `PI_OFFLINE=1`, and no credentials or prompts.
No user configuration was activated or reloaded.

Observed:

- **PASS:** real plain-terminal startup created the repository session and task
  editor/shell/Pi panes. Guardian loaded, Pi stayed alive and bound the expected
  coordinator UUID and task paths. The terminal was opened explicitly with
  `footclient -E`; the launcher itself used its plain-terminal branch.
- **PASS:** launch lock was released while the real terminal remained attached.
- **PASS:** navigation from the original session to the already-attached fixture
  refused with exit 1; pane identities and both clients' focus stayed unchanged.
- **KNOWN COSMETIC LIMITATION:** cold client's actual focus remained on editor `terminal_3` rather
  than Pi `terminal_4`. A direct `focus-pane-id terminal_4` returned exit 0 but
  `list-clients` still reported `terminal_3`. Pane `is_focused` flags alone were
  misleading: more than one pane reported focused.
- **Root cause verified in pinned source:** CLI messages carry `client_id: None`
  (`zellij-client/src/cli_client.rs`); server routing uses
  `get_last_active_client().or(maybe_client_id).unwrap_or(client_id)`
  (`zellij-server/src/route.rs`). Before the first real key event, last-active
  is unset, so focus is routed to the transient CLI connection despite one
  attached terminal. Counting clients does not repair routing.
- **At this initial run**, session transitions, launcher `--window`, picker
  exit and recovery were not exercised. Later runs below add window and
  current-terminal lifecycle coverage. Cross-repository session transitions,
  controlled detached attachment and missing-Pi/full recovery remain unverified.

Preserved fixture (IDs below describe the original run, not current live bindings):

- Root: `/tmp/pi-task-live-hMCEC4`; repository: `plain`; task: `native-plain`.
- Worktree: `/tmp/pi-task-live-hMCEC4/plain.worktrees/native-plain`.
- Session: `plain-cb009fbbd665`, task tab ID `1`; editor `3`, Pi `4`, shell `5`.
- Task Pi PID `2451955`, UUID `70a456b5-b1eb-4fc2-812c-840080ee851b`.
- On follow-up inspection, the fixture session was no longer listed and
  `/tmp/pi-task-live-hMCEC4/plain.exit` recorded launcher exit `0`. This was not
  a controlled detach/lifecycle test. Do not assume its former processes or
  panes still exist. Saved repository/worktree state remains.
- Disposable foot window ID `108`, app ID `pi-task-live-hMCEC4`. Original
  `shinyflakes` client/pane `20` was not detached or replaced; original desktop
  window ID `2` was refocused after inspection.
- Disposable `switch` and `window` repositories also remain under the fixture
  root; `window` was used in the follow-up below. No agent cleanup was performed.

#### Follow-up smoke — 2026-10-23: explicit window and current terminal passed

- Added `footclient --client-environment`; regression fixture requires the flag.
  Native `--window` used package
  `/nix/store/rb1mm5kb7w1crq5h7ixirm8m60d7mnar-pi-task`, creating
  `/tmp/pi-task-live-hMCEC4/window.worktrees/native-window` in session
  `window-835e5ee3843c`. Process environments confirmed isolated Pi config/cache,
  offline mode, task bindings on task Pi, and no task bindings on the initial
  project-layout Pi. Launcher exited 0. That session is no longer live.
- Agent-created scratchpad on the untouched disposable client failed with
  `No active tab for client`; this is not a test of keyboard-driven picker use.
  No native routing patch or synthetic key-event workaround was applied.
- User requested testing in the actual current `shinyflakes` terminal. Launched
  the rebuilt picker in a floating scratchpad with `close_on_exit`, matching
  Alt-T's launcher lifecycle, without opening another window. The installed
  Alt-T command itself was not replaced or activated.
- User selected `[new task]`, named it `step2-current-terminal`, and left the
  request empty. Picker pane `71` exited with status 0 and disappeared. Task tab
  `1` retained live editor `72`, Pi `73` and shell `74`.
- Reopening exposed an unnecessary focus call: changing tabs had already
  restored Pi focus, so `focus-pane-id` returned “already focused” as an error.
  Launcher now checks the sole client's actual pane after changing tabs and
  skips redundant focus. A focused open/resume regression covers this behavior;
  no generic error suppression was added.
- With final package `/nix/store/f96aqhcplvjjhbizgz4239w775br3834-pi-task`, both
  `open` and live `resume` returned success and `list-clients` reported Pi pane
  `73`. All three pane IDs/commands remained unchanged: no duplicate Pi, no
  replacement editor, no request replay. Returned focus to original pane `20`.
- Final source regressions and offline build passed. Node suite: 235 passed,
  one optional Neovim test skipped. No activation or Step 3 work.

Current-terminal fixture, last verified live (revalidate before reuse):

- Worktree: `/home/lucas/shinyflakes.worktrees/step2-current-terminal`.
- Branch: `task/step2-current-terminal`; fixed base
  `a801b2657d4baf639624e93e7a4a8a455b8b3581`; worktree status clean.
- Session `shinyflakes`, tab `1`; editor `72`, Pi `73`, shell `74`.
- Pi UUID `3f41aa0c-fde3-497d-a326-fdd839c09fc3`; request empty;
  launch marker false; coordinator bound. Exact missing-Pi recovery was not tested.
- Temporary picker driver: `/tmp/pi-task-live-hMCEC4/current-picker.sh`.
  No automatic pane/worktree cleanup; do not start another task with this name.

#### Session-transition smoke — 2026-10-23: creation passed, cold return blocked

User approved disposable fixtures and temporary client switches. Reused package
`/nix/store/f96aqhcplvjjhbizgz4239w775br3834-pi-task` and existing fixture root.

- **PASS:** `new native-switch` in `/tmp/pi-task-live-hMCEC4/switch` moved the
  sole current client from `shinyflakes` into new session
  `switch-f73a5d64a311`. Launcher exited 0; task tab `1` had live editor `3`,
  Pi `4`, shell `5`. Pi UUID `cea5d080-4c50-4102-901f-c6d9eb1dd535`, model
  `codex-personal/gpt-6-sol`, empty request. Actual client focus remained editor
  `3`, consistent with the accepted cold-focus limitation.
- Native switching inherited the original terminal client's environment, not
  launcher-shell overrides for isolated Pi config/cache/offline mode. The new
  Pi therefore used the installed runtime, not the isolated Guardian fixture;
  no prompt was sent. This was not an isolated-runtime compatibility test.
- **FAIL:** native `switch-session shinyflakes --tab-position 1 --pane-id
  terminal_20` returned 0, but subsequent client listings still showed one
  client in the disposable session and none in `shinyflakes`. This affects
  essential switching, not only cosmetic focus. No synthetic key event used.
- **BLOCKED:** subsequent `new native-detached` refused the still-attached
  destination. It preserved its branch/worktree and empty review state, with
  no coordinator or Pi launch. Existing panes `0`–`5` remained unchanged.
  This is an attached-target refusal, **not** a detached-attachment pass.
  Never retry `new` for either fixture.
- Human activity subsequently appeared in the disposable session; by the next
  guarded return attempt it was detached, so the guard aborted without issuing
  another switch. `shinyflakes` client/pane `20` was later verified restored.
  Do not attribute this restoration to the failed CLI command. No cleanup.

User then approved native-fork work, launched through explicit `--window`:

- Repository: `/home/lucas/git/private/zellij`; task worktree:
  `/home/lucas/git/private/zellij.worktrees/client-targeted-navigation`.
- Branch `task/client-targeted-navigation`, fixed `integration` base
  `fffb2324b3e23a10fc467f14c293902400410c14`; model `codex-work/gpt-6-astra`.
- Existing detached session `zellij` attached successfully in the new window;
  task tab `1`, editor `15`, Pi `16`, shell `17`. Verified live Pi PID `3094395`,
  UUID `c555e8f7-1d71-409d-b532-780134fedf8d`, model, task/review environment and
  persisted exact coordinator transcript. Revalidate these bindings before reuse.
- Scope: native cold-client targeting for switch/focus, multi-client safety and
  focused regressions; no synthetic keys or launcher workarounds. Build/test,
  then report before the approved integration merge. No push or activation.
  Main checkout's untracked `flake.nix`/`flake.lock` were not copied or changed.

#### Native debug-build smoke — 2026-10-23: cold navigation passed

User approved a fresh disposable window/server, leaving existing sessions alone.
Used the task worktree's `target/debug/zellij` (Oct 23), not main checkout's old
Oct 20 binary. Frozen copy at `/tmp/zellij-native-cold-2M2Oi6/zellij`, SHA-256
`cdd97b2a62e471efe38f84db7a80ad1a7921ffa257ec7c00f2eebcccd2811300`.

- Actual native client ran in footclient through `script`, recording rendered
  terminal output. Minimal config used `mirror_session false`; disposable
  panes ran `sleep 86400`, not Pi. Startup welcome floats were hidden through
  native CLI; no synthetic or agent-sent keyboard events.
- **PASS:** cold default-client focus moved actual `list-clients` focus from
  `terminal_0` to `terminal_1`, both initially and in the newly created session.
- **PASS:** switch/create A → B; explicit `--client-id` return B → A; default
  target reattach A → detached B → A. Observed zero source/one destination
  clients, and restored pane focus. Returning clients received new IDs.
- **PASS:** invalid ID, stale former ID and navigation into a zero-client
  session refused with exit 2, without changing attached client's focus.
- **PASS:** background `new-tab --no-focus` preserved focus; explicit tab/pane
  navigation worked and returned to the original pane. Captured terminal stream
  contained rendered pane titles but no `MY FOCUS` or `FOCUSED USER` banner.
- Initial observation queried newly created B before startup completed and
  aborted on its missing-session response. Subsequent inspection confirmed B
  ready; continued without resending creation/switch. Readiness still matters.

Preserved fixture: session `native-cold-2M2Oi6-a` attached, last client ID `24`
focused on terminal `1`; session `native-cold-2M2Oi6-b` detached. A has original
panes `0`/`1` and background tab `1` panes `2`/`3`; B has panes `0`/`1`.
All sleep jobs and the recording window remain running; no cleanup authorized.
Artifacts under `/tmp/zellij-native-cold-2M2Oi6`: `observations.json`,
`roundtrip-observations.json`, `smoke-summary.json`, `terminal.log` and
`terminal-plain.log`. Revalidate bindings before reuse.

This does not establish full `pi-task` compatibility, multi-client native smoke,
or mixed old/new client-server compatibility. No installed binaries, existing
sessions, main checkout files or task implementation were changed by this smoke.

#### Packaged integration/direct startup — 2026-10-23: blocked

Revalidated after native task completion: `41857042` was merged/pushed as
`c10ec77e` in a separately authorized workflow. Installed launcher
`/nix/store/id2gl4rlbjzcnq4qxvb8x5bi1k9ka1ab-pi-task` matches checkout runtime
sources and explicitly prepends fixed Zellij
`/nix/store/l1qkcnridf2qn095iw2v6ll48ns3cxdq-zellij-0.46.0-fork/bin` to PATH.
The shared Pi library link now exists. These are observed external changes,
not activation performed by this coordinator.

- **FAIL:** `new fixed-launch --window` in `/tmp/pi-task-live-hMCEC4/plain`
  timed out waiting for a client. Its base project panes existed but
  `list-clients` was empty and user reported frozen input. Worktree
  `plain.worktrees/fixed-launch` and empty review state remain; no coordinator,
  task Pi or request delivery. Do not retry `new` or replay a request.
- User paused launcher tests and requested direct native diagnosis.
  Direct packaged startup through `footclient → script → zellij` worked with
  both minimal configuration and the real `project` layout/configuration;
  native focus commands moved the sole client. User confirmed these worked.
- **REPRODUCED without pi-task:** exact `setsid -f → footclient → zellij`
  path, launcher runtime PATH and immediate `list-clients` polling froze
  `direct-raw-LFmZ83`. Source/layout creation completed, but client list stayed
  empty for 100 bounded observations. User confirmed frozen window.
- Raw log reports `active tab not found for client 1` immediately at initial
  layout application, then on mouse input. This is not absence of input events.
  Source defect identified in `zellij-server/src/screen.rs`: `remove_client`
  advances `highest_client_id_seen` even for temporary CLI clients; initial
  `apply_layout` treats every lower ID as already disconnected. Early CLI
  cleanup can therefore prevent the real first client's tab attachment.
  At this checkpoint, deterministic regression/fix remained pending. October 24's
  new-build smoke below supersedes the startup blocker; no sleep workaround was added.
- Evidence: `/tmp/zellij-direct-LFmZ83/raw-start-observations.json` and
  `raw/zellij-1000/zellij-log/zellij.log`; successful direct-session logs and
  terminal recordings are alongside them. Session names:
  `direct-nix-LFmZ83`, `direct-project-LFmZ83`, `direct-raw-LFmZ83`.
  No sessions, windows or worktrees were cleaned up; revalidate live state.

#### New installed build — 2026-10-24: startup and explicit-window launcher passed

User approved disposable windows, then confirmed responsive input for each
successful smoke. Existing user sessions were not restarted, detached or changed.

- Verified profile Zellij resolves to
  `/nix/store/261h2bi9f780jfvys3gj15w8p6zc1364-zellij-0.46.0-fork/bin/zellij`.
  Existing servers and this coordinator's inherited PATH still used `l1qkcn…`.
  `/proc` and window listings identified the reported frozen About/tip window
  as the old `direct-raw-LFmZ83`, not a new-build failure.
- The new derivation's source, `/nix/store/j9vl0g2bmgm7jn7bbr2pxa26k2z408r3-source`,
  uses `pending_clients.remove(&client_id)` in `screen.rs::remove_client`;
  `highest_client_id_seen` is absent from that file. This session did not
  implement the native fix, establish its exact commit, or rerun its regressions.
- Two initial shell-only launch attempts using `--layout-string` exited with
  `Session 'zellij-new-smoke-sRd9UQ' not found`; neither created a session.
  After explicit user approval, startup used `--new-session-with-layout` and a
  temporary layout file. These invocation failures are not frozen-client evidence.
- **PASS, shell-only:** session `zellij-new-smoke-sRd9UQ`, client `1`, shell pane
  `0`. New client/server executables verified through `/proc`. Immediate bounded
  `list-clients` polling observed attachment on poll 5; user confirmed input worked.
  No bars were expected in this minimal layout.
- **PASS, real project layout:** session `zellij-project-smoke-kkw3qp`, client `1`,
  editor `0`, Pi `1`, shell `2`. Used installed
  `~/.config/zellij/layouts/project.kdl`; both bars loaded, attachment appeared on
  poll 9, and user confirmed bars/input worked. No Pi prompt was sent.
- **PASS, actual launcher:** package
  `/nix/store/n4xd889vpr4zrqvb2203w6ycby7r3i5h-pi-task` matched checkout
  `cli/{pi-task,review,runtime}.ts`, `lib/task-state.ts` and `package.json` byte
  for byte. Its wrapper pins the new Zellij. Ran `new launcher-smoke --base HEAD
  --request '' --model codex-personal/gpt-6-sol --window` in a fresh disposable
  repository. The real `setsid → footclient → zellij` path and launcher readiness
  polling completed with exit 0. Sole client `1` focused task Pi `4`; editor `3`
  and shell `5` remained live in task tab `1`. User confirmed all panes/bars/input.
- Task Pi PID `297208`, UUID `43332981-af65-4602-b98b-63be738ffdf0`, model and
  task/review environment were verified. Guardian was loaded and idle, coordinator
  UUID bound, empty request preserved and `piLaunch` false. Herd advertised a
  session file, but inspected review state had no `coordinatorSession`; exact
  transcript persistence/recovery was not established. No request was replayed.

Preserved fixtures (revalidate before reuse):

- Shell smoke directory `/tmp/zellij-new-smoke-sRd9UQ`; its shell window and
  failed-launch diagnostic window were left open.
- Project-layout directory `/tmp/zellij-project-smoke-kkw3qp`; panes and window
  remain running.
- Launcher root `/tmp/pi-task-new-smoke-o9kxrS`; logs `launcher.log` and
  `launcher.exit`; repository `repo`; worktree `repo.worktrees/launcher-smoke`.
- Launcher session `repo-d5ce4ca3b00e`, branch `task/launcher-smoke`, fixed base
  `0437b17d6391242c6bebba36511d53cf6df356a5`. Worktree was clean. Inspect with
  `pi-task --repo /tmp/pi-task-new-smoke-o9kxrS/repo state
  /tmp/pi-task-new-smoke-o9kxrS/repo.worktrees/launcher-smoke`; explicit `--repo`
  is required from this coordinator's different repository. Never retry `new`.

No cleanup, activation, implementation edits or automated suite rerun occurred.
These passes establish startup and explicit-window launcher integration, not
cross-session switching, controlled detached attachment, exact transcript
recovery, multi-client navigation, or mixed-version compatibility on this build.

#### Packaged session transitions — 2026-10-24: passed

User approved one disposable client moving between two disposable repositories,
plus attached-target refusal and documentation. Used the same `n4xd889…` launcher
and `261h2bi…` Zellij; no synthetic keyboard input, extra window or existing-user
session navigation. Caller session/pane context was supplied explicitly to the
launcher from this coordinator; no text was injected into either shell.

- **PASS, switch/create A → B:** revalidated A `repo-d5ce4ca3b00e`, sole client
  `1` on task Pi `4`, before creating `transition-smoke` in a second fresh repo.
  Ran `new --base HEAD --request '' --model codex-personal/gpt-6-sol` without
  `--window`. Exit 0; A had zero clients, B `repo-34b59b63b534` had client `1`
  focused on task Pi `4`. Both repositories are named `repo`; session hashes
  correctly kept them distinct.
- **PASS, return B → A:** `open` of A's worktree with explicit `--repo` exited 0.
  B had zero clients; A had returning client `41`, focused on original Pi `4`.
- **PASS, controlled detached reattachment A → B:** `resume` of B's worktree
  exited 0. A had zero clients; B had returning client `31`, focused on original
  Pi `4`. This resumed navigation to a live coordinator, not a closed Pi.
- **PASS, attached-target refusal:** `resume B --window` exited 1 with
  `already attached or client state unknown`. B's client `31`/focus stayed
  unchanged; A remained detached. No second client was actually attached, so
  this is refusal coverage, not a native multi-client routing test.
- Assertions after each transition compared both sessions' terminal pane IDs,
  tab IDs, launch/process commands and live/exited state against snapshots.
  Each task retained editor `3`, Pi `4`, shell `5` in tab `1`; no duplicate or
  replacement panes. Guardian PID/session/task bindings and idle status stayed
  unchanged, both review coordinators matched, requests remained empty and
  `piLaunch` remained false. Window app/count comparison found no extra window.
- Process inspection confirmed the client and both repository servers use the
  new Zellij executable. B's worktree was clean. User confirmed the window
  remained responsive after the round trip. No model prompt was sent;
  no transcript persistence/recovery claim follows from these checks.

Preserved state, last observed (revalidate before reuse):

- A: `/tmp/pi-task-new-smoke-o9kxrS/repo.worktrees/launcher-smoke`, session
  `repo-d5ce4ca3b00e` detached; Pi PID `297208`, UUID
  `43332981-af65-4602-b98b-63be738ffdf0` remains alive.
- B: `/tmp/pi-task-transition-pYR9ny/repo.worktrees/transition-smoke`, branch
  `task/transition-smoke`, base `ec799bbb89225fc76163380fa13158310ead4d53`,
  session `repo-34b59b63b534` attached, client `31` on pane `4`; Pi PID `314242`,
  UUID `7e836824-0fba-4cc3-be02-ec61d2da72d1`, model `codex-personal/gpt-6-sol`.
- Evidence directory `/tmp/pi-task-transition-pYR9ny`: launch/return/reattach/
  refusal logs and exit files, before/after pane and client snapshots,
  `identities-before.json`, `windows-before` and `windows-after`.
- Earlier standalone shell/project windows were no longer listed when this
  slice began; their previous running-state notes are historical. No cleanup
  was performed by this coordinator. Both repository task workspaces remain.

The earlier startup-only coverage boundary is superseded for these transitions.
Exact transcript recovery, actual multiple-client routing and mixed-version
compatibility remain untested. No source suite rerun, activation or Step 3 work.

#### Missing-Pi recovery preparation — 2026-10-24: blocked before closure

User approved one marker prompt and closure of only B's task Pi. Prompt
`Reply exactly RECOVERY-SMOKE-OK. Do not use tools.` was entered once; transcript
later contained one user message and one completed `RECOVERY-SMOKE-OK` reply,
with no tool calls. Initial screen/file inspection was premature; no prompt was
resent. Review state now records `coordinatorSession`, matching the existing
UUID, worktree-root header and herd locator.

Before closure, identity guard found herd PID `314242` reporting
`zellijSession: "4c4af049ad7c"` instead of `repo-34b59b63b534`. Pi and its pane
were still alive. `herd.ts::resolveSession` assumes socket filenames are session
names and replaces the inherited name after a scan. This fork uses stable socket
IDs; B's server socket ends in `contract_version_1/4c4af049ad7c`.
A live `pi-task resume` reproduced exit 1: `live Pi active session unknown or
differs from saved coordinator`. Logs: `/tmp/pi-task-transition-pYR9ny/`
`recovery-identity-refusal.{log,exit}`. No replacement launched, pane closed,
state manually changed or request replayed. Earlier transition passes preceded
this identity refresh and do not establish continued live-resume reliability.

#### Guardian fix and conversation recovery — 2026-10-24: passed; geometry follow-up below

User approved the identity fix, regression, disposable-only reload and repeat
recovery. `pi/extensions/tool-guardian/herd.ts` now discovers names with
`zellij list-sessions --no-formatting --short`, not socket filenames. Status
writes keep a 30-second scan cooldown; notification identity forces a fresh
lookup. Existing ambiguous matches retain the previous name rather than choosing
another session. CLI failures and non-live/unreadable candidates do not invent
an identity. Existing dirty edits were preserved; launcher checks were not relaxed.

- Extended `tests/notify.test.ts` covers opaque socket IDs, unchanged socket
  across renames, absent/failed/ambiguous name discovery, malformed panes/plugin
  exclusion, saved herd identity and status-scan throttling. It failed against
  the old implementation and passed with the fix.
- Full shared-state/Guardian Node suite: **235 passed, 1 optional Neovim
  acknowledgement test skipped**. Test command pane `shinyflakes:terminal_9`
  completed with exit 0. Original bottom shell survived; editor/agent rectangles
  and actual focus stayed unchanged.
- `/reload` on B's disposable Pi restored canonical herd session name with the
  same PID, UUID and transcript. Live packaged `resume` then passed. Other
  running Pi instances were not reloaded and may still have old discovery code.
- Verified durable transcript header, one marker prompt/reply and exact review
  locator before closing only B's task Pi `terminal_4`, PID `314242`. Confirmed
  that process exited; editor `3` / PID `314239` and shell `5` / PID `314245`
  remained alive with unchanged process start times.
- Packaged `pi-task resume`, invoked with surviving shell `5`'s session context,
  exited 0 and created only Pi `terminal_6`, PID `456035`, in existing task tab
  `1`. Sole client `31` focused pane `6`. New Pi used native `--session` with the
  exact saved file, UUID `7e836824-0fba-4cc3-be02-ec61d2da72d1`, restored model
  `codex-personal/gpt-6-sol`, and correct task/review environment.
- **PASS:** marker prompt/reply visible in restored TUI; transcript bytes and
  complete review state unchanged, no replayed prompt/new model turn, empty
  original task request retained and launch marker false. All other terminal
  pane IDs/commands survived; worktree stayed clean.

At this checkpoint B used session `repo-34b59b63b534`, Pi pane `6` / PID
`456035`; the geometry follow-up below supersedes that pane/PID binding.
Evidence in `/tmp/pi-task-transition-pYR9ny`: `guardian-session-`
`{red,green}.log`, `guardian-suite.{log,exit}`, `recovery-live-fixed.log`,
`recovery-resume.{log,exit}`, `recovery-{baseline,summary}.json` and pane/process
snapshots. Source is live-symlinked into Guardian; no launcher source change,
Nix rebuild, system activation, cleanup or Step 3 work occurred. Full-workspace
recreation, actual multi-client routing and mixed-version compatibility remain
outside this smoke.

#### Standard recovery geometry — 2026-10-24: fixed and native-checked

User reported the restored Pi/editor side by side above a full-width shell.
Before/after snapshots confirmed the generic `new-pane --tab-id` recovery path
split the largest remaining pane. The preceding conversation/process checks
missed geometry, so that smoke was not a complete layout-recovery pass.

User approved standard task-layout repair, regression coverage and a rebuilt
launcher, not arbitrary custom-layout restoration.

- Native source verified `override-layout` reuses exact launch-command matches.
  First repaired B's existing tab in place with both retention flags and
  `--apply-only-to-active-tab`. All terminal IDs/PIDs and transcript bytes
  survived; geometry returned to editor `(0,1,111×31)`, shell `(0,32,111×14)`,
  Pi `(111,1,74×45)` at the observed terminal size.
- `pi/cli/pi-task.ts` now shares the standard layout between new-tab creation
  and missing-Pi recovery. Recovery reuses the surviving shell's original launch
  command, selects/verifies the sole client's task tab, and applies the layout
  with existing terminals/plugins retained. Existing tab names/review cues are
  not overwritten. Only Pi is spawned; editor/shell are matched and reused.
- Recovery refuses unsupported survivor sets (extra, exited, floating or
  suppressed terminals, or missing bound editor/shell) before launching anything.
  It verifies surviving pane identities and full-height Pi/left-only-shell
  geometry before reporting success. Custom-layout restoration remains excluded.
- `packages/tests/pi-task-resume.sh` now covers layout command reuse, proportions,
  original shell preservation despite a different caller shell, tab title/review
  cues, unsupported survivor refusal and visible-but-wrong-geometry failure,
  alongside existing concurrency, timeout, identity and presentation tests.
- **PASS:** Bash syntax and resume/presentation fixture; full Node suite
  **235 passed, 1 optional Neovim test skipped**; offline Nix build; diff checks.
  Final package `/nix/store/7rcic2i6n9h9643mrfwaq8fn5zg6br61-pi-task` matches runtime
  sources and pins Zellij `261h2bi…`. It has not been activated.
- **PASS, final rebuilt-package native recovery:** closed only disposable Pi `7`
  / PID `563482`, then `resume` exited 0 and restored Pi `8` / PID `613048` in
  task tab `1`; client `31` focused it. Every terminal rectangle matched the
  repaired baseline; all other terminal IDs/commands/tab names and plugin IDs
  survived.
  Editor PID `314239` and shell PID `314245` retained their start times.
  Same conversation UUID, byte-identical transcript, unchanged review state,
  empty original request and cleared launch marker; no new model turn.
  Repeated live `resume` also passed without changing panes or transcript.
  User subsequently confirmed corrected layout visually and closed the test phase.

Latest B binding: `repo-34b59b63b534`, Pi pane `8` / PID `613048`, UUID
`7e836824-0fba-4cc3-be02-ec61d2da72d1`; worktree/base unchanged. Revalidate
before reuse. Evidence under `/tmp/pi-task-transition-pYR9ny`:
`layout-repair-{before,after}.json`, `layout-final-*`, `layout-native-*.log`,
`layout-recovery-{before,after-panes,summary}.json` and final `layout-release-*`
logs, snapshots and summary. Check/build command panes `shinyflakes:terminal_10`,
`terminal_11` and `terminal_12` completed with exit 0; logs saved above.
No cleanup, system activation, full-workspace recovery or Step 3 work.

### Step 3: main-checkout tasks — implemented and automated-checked

User approved the bounded file-level plan in the existing shared checkout.
Implementation preserves the version-2 review format and CLI mutation/locking
boundary; no daemon, global registry, branch switch or bulk migration was added.

- New tasks get UUID metadata/review paths, fixed bases and independent native
  session IDs. Legacy checkout-hash IDs, requests, models and review history stay
  in place. `state`/`resume` accept IDs; ambiguous names/checkout paths use a picker.
- `new NAME --here` preserves checkout, branch and existing edits. Dirty inclusion
  requires explicit consent. Known live agents trigger an advisory shared-writer
  warning and offer isolation; separate metadata does not isolate files or diffs.
- In Zellij, `--here` stacks Pi in the current tab's verified, visible same-checkout
  Pi area. Missing/ambiguous Pi areas refuse launch; use `--here --tab` for a new
  full tab. Existing editor/shell/conversation processes and rectangles survive. Plain
  terminal `--here` runs Pi directly and releases the launch lock while it runs.
- Shared recovery checks server PID/start time and persistent editor/shell anchors.
  Stale/moved/partial anchors fail closed. A wholly missing workspace becomes a
  dedicated standard layout, retaining exact transcript recovery without replay.
- `open PATH` never adopts or starts Pi. An unregistered checkout gets editor/shell
  presentation only. Explicit paths select their repository from any cwd; a
  conflicting `--repo` fails clearly.
- Picker separates Start here / New isolated task / Open checkout and Open / Resume
  / New conversation. Rows distinguish task title/ID, checkout, pending review,
  agent state, surviving workspace and available activity timestamps.
- Guardian uses explicit review identity for editor/title routing. Native `/new`
  detaches review context instead of stealing coordinator ownership; ordinary
  `/review` follows HEAD. Native custom session metadata preserves detachment over
  reload; explicit `/review-coordinator` remains the transfer path. Shared tabs
  avoid conflicting tab-wide title/review cues. Modern title calls use `--task-id`
  so older CLIs reject rather than rename a legacy task in the same checkout.

Validation completed:

- Resume/presentation fixture passed, including unchanged Steps 1–2 safeguards.
  Shared Zellij stub now lives at `packages/tests/fixtures/pi-task-zellij.py`.
- Full Node suite: **240 passed, 1 optional Neovim acknowledgement test skipped**.
  Added main-checkout/PTY, independent-ID, picker, shared recovery, native session
  switch/reload and same-checkout title/editor routing checks.
- Isolated offline Pi shared-library loader passed. Offline `pi-task` build passed;
  **6 packaged-CLI/Guardian compatibility checks passed**, including independent
  task IDs and empty-PATH state operations. Bash syntax and both diff checks passed.
- Package: `/nix/store/rf5v73c7nc632iqxvpr30f241807pn7x-pi-task`.
  Logs: `/tmp/pi-task-step3-0C725P/` (`resume-verified.log`, `node-complete.log`,
  `loader-complete.log`, `final-build.log`, `final-packaged.log`).
- Checks ran in managed bottom-stack command panes, preserving the original shell,
  editor/agent rectangles and keyboard focus. Completed panes `13`–`20` retain
  output; early fixture failures were corrected. No check remains running.
  An early cross-path fixture could reach an unstubbed `footclient`; final fixtures
  stub it from setup. No related test process remained on inspection, and no
  native window/startup success is inferred from that attempt.

The initial implementation did not perform native Step 3 smoke or activation.
The approved follow-up below supersedes that smoke status. Steps 1–2 remain
accepted; their waived cases are not reopened.

#### Disposable Step 3 smoke — 2026-10-24: stack/open passed; initial `/new` failure fixed below

User approved fresh disposable repositories, one window, empty requests, no
activation or cleanup. Fixture root: `/tmp/pi-task-step3-native-0Aw9hT`.
The initial `rf5v73…` package matched runtime source; Zellij is `261h2bi…`.
Pi used isolated settings/cache, offline mode, source Guardian/provider aliases,
and model `codex-personal/gpt-6-sol`. No credentials were copied.

- **PASS:** `--here --tab --window` created task `dedicated-a` in the fixture's
  main checkout. `--here` refused dirty tracked/untracked files without consent;
  explicit `--adopt include` preserved bytes, branch, HEAD, worktree list and the
  previous task's review. Concurrent-agent warning appeared.
- **FAIL, original placement:** generic `new-pane --tab-id` split Neovim's area.
  User clarified that `--here` must stack where Pi normally lives. Existing
  processes survived, but this was not correct presentation.
- **FIX:** shared launch and recovery now select one visible live same-checkout
  Pi via herd identity and stack with `ZELLIJ_PANE_ID`, `--stacked --no-focus`,
  without `--tab-id`. Missing/ambiguous/foreign/floating anchors refuse before
  launch. Post-launch checks preserve all existing terminal identities/rectangles
  and require the new Pi to occupy its anchor's rectangle. Existing server and
  editor/shell recovery guards remain.
- **PASS, rebuilt native placement:** `rc1dfkh…` created `stack-base` in a fresh
  full tab, then `stack-here` and `stack-again` in its right-hand Pi stack.
  Editor `(0,1,111×31)` and shell `(0,32,111×14)` stayed unchanged; all three
  Pis occupy `(111,1,74×45)`. Old Pis remain alive and display-suppressed.
  IDs, native sessions and review states are independent; first/second bases
  differ. Dirty bytes and previous review bytes survived. No model prompt sent
  by these native launches.
- **PASS, external worktree:** from a different repository cwd, explicit `open`
  selected a dirty unregistered linked worktree and added only editor/shell.
  No task/review adoption, no Pi, unchanged HEAD/files; repeat open added nothing.
  Conflicting `--repo` refused. Returning via the live `stack-here` task ID passed.
  This used the existing disposable repository session, not cold repository startup.
- **FAIL, native `/new`:** `stack-again` changed its conversation UUID but herd
  retained its old task review identity, no detachment notification appeared,
  and no new transcript/detachment entry existed. Original review stayed byte-
  identical. `resume` correctly refused the changed active conversation without
  replacement. This checkpoint preceded the Guardian fix and successful native
  `/new`, reload and ordinary review follow-up below.
- **CHECKS:** corrected focused tests (3), resume/presentation fixture, full Node
  suite (**240 passed, 1 optional skip**), offline build and both diff checks passed.
  Added coverage for missing/invalid/ambiguous Pi anchors and wrong stack geometry.
  Shared missing-Pi recovery is automated-covered, not native-claimed here.
- **TEST ISOLATION INCIDENT:** initial existing PTY fixture inherited fish;
  shell startup bypassed its stub PATH and real Pi submitted test text `ONCE`.
  Provider returned HTTP 429; process scan found no survivor. User was informed
  before continuing. Both PTY fixtures now force `/bin/sh` without startup hooks;
  the plain-Pi fixture also checks stub resolution and passes explicit PATH.
  Corrected suites passed. Do not claim the whole test run made no model requests.

Latest bindings (revalidate before use): session `repo-ea2933cf65d2`, tab `2`,
editor `12`, shell `14`, Pis `13`/`15`/`16`. Task IDs:
`stack-base` = `da7543ad-706c-44d4-9fd6-3f949575d43c`,
`stack-here` = `36c916bb-3fb7-466d-8fa4-0c192caccaaa`,
`stack-again` = `bd981e37-a4fd-4cb9-8620-c29baea5161f` (Pi switched by `/new`).
Root is `/tmp/pi-task-step3-native-0Aw9hT/repo`; external worktree is sibling
`external-worktree`. User changed some original fixture panes during the pause;
old pane IDs are historical, not safe cleanup targets. Completed check pane `10`
and native-runner pane `11` exited 0; disposable Pi/editor/shell processes remain.
Evidence: `native-stack-summary.json`, `stack-*-{before,after}-panes.json`,
`external-summary.json`, `new-{screen.txt,original-review.json,resume.log}`,
`stack-{focused,resume,node,build}.log`, `stack-build.path`, and the preserved
`stack-focused-initial-failed.log`. No activation, user-session reload, source
commit or agent cleanup occurred.

#### Guardian replacement lifecycle — 2026-10-24: fixed and native-checked

User approved lifecycle repair, regression and disposable-only reload/retest.
Pi 1.3.0 source (`agent-session-runtime.ts::newSession`/`switchSession` and
`extensions/types.ts::SessionStartEvent`) confirms session replacement constructs
a new extension runtime and emits `session_start.reason`. Guardian's closure-local
`activeSession` therefore reset before it could recognize `/new`.

- Removed that variable. Detachment now uses native `new`/`resume`/`fork` reason
  plus existing session metadata; matching saved coordinator still restores task
  context, startup children retain ownership rules, and reload honors detachment.
- Regression now creates fresh Guardian factories for each replacement reason,
  rather than incorrectly reusing one factory. It failed against the old code
  (missing detachment entry), then passed with the fix. Checks also preserve
  named review bytes, ordinary HEAD baselines, no feedback replay, reload behavior
  and explicit ownership transfer.
- **PASS:** full Node suite **240 passed, 1 optional skip**, isolated offline loader,
  and both diff checks. Launcher package remains `rc1dfkh…`; this fix changes live
  Guardian source, not the packaged launcher. No system activation occurred.
- **PASS, native:** reloaded only `stack-base` Pi pane `13` / PID `1133648`.
  `/new` changed UUID to `01a16e26-9810-7379-9f45-f65b3e4b07bc`, emitted the
  detachment notification and cleared herd's task review identity. `/reload`
  retained that UUID and detached context. All named task reviews stayed byte-
  identical. These idle sessions had no transcript file yet, so this proves
  in-process reload persistence, not disk/restart recovery of a promptless session.
- **PASS, ordinary review:** `/review` opened real Diffview in existing editor
  `12`, with separate `session-reviews/d274737f9246b982b0be0dd26d78a540848c80b65f372c614ede2f23581c4704.json`,
  coordinator matching the new UUID, and HEAD base
  `e51d905fba80463113bd198ce5abffe0e49f0252` rather than the named task's older
  base. No named review changed, no feedback submitted, no model turn started.
  Disposable ordinary review remains open; fixture processes/window remain.

Evidence in the same fixture root: `lifecycle-{red,green,loader}.log`,
`lifecycle-new-summary.json`, `lifecycle-reviews-before.json`,
`lifecycle-review-summary.json` and `lifecycle-*-screen.txt`/review screen dumps.
Red regression pane `19` exited 1 as expected; corrected checks pane `20` exited 0.
`stack-base` and `stack-again` panes now hold different conversations from their
saved task coordinators; do not blindly `resume` or transfer either task.
`stack-here` pane `15` remains its original live coordinator.
Native picker interaction, shared missing-Pi recovery and disk restart of a
promptless detached session were not tested here; automated coverage is separate.
No cleanup, activation, source commit or reload of existing user Pis occurred.

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

Default: reuse the caller's window. Step 2 requires explicit `--window` without
a usable terminal; it does not infer desktop intent from a noninteractive call.
Navigation is single-client only, as described in the implementation status.

| Invocation context | Default |
| --- | --- |
| Inside Zellij | Reuse the current client; focus a workspace or create a task tab |
| Plain interactive terminal | Run or attach in that terminal |
| Existing Pi | Keep its conversation unless explicitly switching; additional work uses a separate pane/tab |
| Desktop launcher without a terminal | Pass `--window` and an explicit command/target to open footclient |
| Noninteractive automation | Require an explicit presentation choice; do not silently spawn a GUI |

`--window` and `--here --tab` are implemented; bounded Step 3 native smoke is
recorded above (activation remains separate):

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
- Alt-T retains `close_on_exit true` in `modules/aspects/shell/zellij.nix`:
  pinned-fork source closes the originating picker pane by ID. Live lifecycle
  verification is still required before claiming a native smoke passed.

## Implementation language and shared core

Implemented as a separate migration after reliable resume, before independent
task identity. The public `pi-task` CLI and Nix package remain unchanged;
launcher/state application logic now runs in TypeScript. This slice preserves
existing lifecycle and recovery guarantees, without implementing Steps 2–3.

TypeScript is preferred because Guardian already uses it: the benefit is one
executable state contract, not types alone. Bash remains suitable for small
wrappers. Python would be reasonable for an independent launcher, but would
retain a second implementation of the contract consumed by Guardian.

### One source of truth

Keep shared code inside the agents submodule so it does not depend on parent
repository source. Runtime layout:

```text
modules/aspects/agents/pi/
├── lib/task-state.ts
├── cli/{pi-task,review,runtime}.ts
├── package.json
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
    bash
    git
    zellij
    fzf
    zoxide
    coreutils
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
can execute source directly:

```bash
node --experimental-strip-types modules/aspects/agents/pi/cli/pi-task.ts --help
```

Migration acceptance: existing resume/state tests still pass; corrupt and legacy
state use the same validation in both consumers; the Nix-packaged command works
outside the source checkout with intact imports and no global Node dependency.
Keep focused failure/recovery tests. Type checking cannot prove a process is
alive or an external launch succeeded.

## Agent-directed Zellij commands

Long-running builds, tests, dev servers and log followers use new named panes
stacked in the layout's existing bottom terminal area. Its persistent shell
stays running as a stack member: no in-place replacement, additional split or
stack over the editor/agent. This is a native CLI instruction convention, not
a new process manager or change to named `pi-task` workspace layouts. Short
commands still belong in the ordinary shell tool.

### Permissions and targeting

- Stay within the current task/workspace. Verify the session, tab, and pane
  binding; never infer ownership from a title, screen position, or current cwd
  alone. Revalidate targets after reconnect or session restart.
- Use explicit session and pane/tab IDs. Do not send input to whichever terminal
  happens to be focused or navigate by repeated focus-left/focus-down actions.
- Use `--no-focus` for new command panes. Do not steal focus, switch sessions,
  rearrange existing panes, or replace editors/agents without permission.
- Validate the persistent bottom shell's workspace ownership and tab before
  anchoring a new stack member there. The shell need not be idle: its process
  and pending input remain untouched. If no unambiguous bottom anchor exists,
  ask rather than choosing another split or stacking over unrelated panes.
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
`bottom_pane` is the verified **numeric** ID of that workspace's persistent
bottom shell. Revalidate its session, tab, terminal kind, live state and recorded
ownership immediately before launch; geometry or cwd alone is insufficient.

Inspect panes and choose targets without changing focus:

```bash
zellij --session "$session" action list-panes --json --all
```

Launch directly into the bottom stack, without injecting shell input. Here the
command is a Pi package build; substitute the authorized job:

```bash
pane=$(ZELLIJ_PANE_ID="$bottom_pane" zellij --session "$session" action new-pane \
  --stacked --no-focus --cwd "$root" \
  --name 'build: pi-task' -- nix build '.?submodules=1#pi-task')
```

Source verification: `zellij-client/src/cli_client.rs` reads `ZELLIJ_PANE_ID`
as the CLI's originating terminal. `Action::NewStackedPane` in
`zellij-server/src/route.rs` uses it as `pane_id_to_stack_under` with
`--no-focus`. Do **not** pass `--tab-id`, which overrides the pane anchor;
validate the anchor's tab before launching instead. `--pane-id` on `new-pane`
is for in-place replacement, not stacked placement. The command-local
environment assignment does not change this agent's task identity.

Capture the returned ID, such as `terminal_12`. Verify its tab, command and
bottom-stack placement, the surviving shell process/pane, and unchanged
editor/agent area. Check actual client focus, not only pane `is_focused` flags.
The visible stack member may change despite `--no-focus`; display suppression
is not process suspension. On unexpected placement/focus, report and stop
rather than rearranging panes automatically.

Do not use `--in-place`, `--close-replaced-pane` or `--close-on-exit`. Completed
command panes retain their output; the persistent shell needs no restoration.
The native bottom-stack smoke below validates this launch shape on the installed
fork, independently of the newer client-routing debug build.

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
despite `--no-focus`; the skill records this caveat. This spec does not activate
launcher changes.

#### Bottom-stack smoke — 2026-10-23: passed

User authorized a harmless test in the existing `shinyflakes` workspace.
Used installed `/nix/store/aa65ishfjhqnqq2pvcdh9bdg86bvx4x9-zellij-0.46.0-fork/bin/zellij`,
not the native-routing task's debug build. Verified tab `0`, original bottom
fish pane `2` / PID `4099`, editor `0`, coordinating Pi `20`, and sole client's
actual focus on `terminal_20` before launching.

- `ZELLIJ_PANE_ID=2 ... new-pane --stacked --no-focus` created command pane `86`
  in exactly the shell's existing rectangle. It printed progress, slept eight
  seconds, then completed with exit 0; completion output remained readable.
- A second command anchored to the same original shell pane created `87`,
  intentionally exited 7, and retained its error-test output in that stack.
- Both launches preserved fish PID/start time, editor/Pi rectangles and actual
  client focus. Shell became display-suppressed, not terminated or replaced.
  No shell input, focus switching, additional split or cleanup was performed.
- Snapshots and process identity check: `/tmp/zellij-bottom-stack-mIt6cj`.
  Completed panes `86`/`87` remain available pending explicit cleanup permission.
  Revalidate IDs before reuse. No smoke command remains running.

## Delivery order and acceptance criteria

### Step 1: reliable resume — DONE, user accepted

- [x] Closing only Pi restores the same conversation beside the surviving editor.
- [x] Closing the workspace restores the same conversation in a recreated layout:
  source/fixture covered; full-workspace native smoke waived by user.
- [x] Repeated or concurrent resume does not duplicate Pi or the initial prompt.
- [x] Missing transcripts produce explicit recovery choices.
- [x] Review feedback still targets the correct coordinator.

### Step 2: same-window startup — DONE, user accepted

Automatic Pi focus is optional: leaving the editor focused is acceptable.
Native task creation and session-switching checks passed; validation phase closed.

Approved scope: refuse ambiguous multi-client navigation, including adding a
second destination client. No Zellij fork changes in this slice.

- [x] A missing repository session starts through the current Zellij client.
- [x] A detached session attaches without an extra footclient.
- [x] A plain terminal works without footclient installed.
- [x] `--window` deliberately opens a window.
- [x] Repositories with identical basenames remain distinct.
- [x] Picker exit does not kill launched task panes.

### Step 3: main-checkout tasks — source/automated checks complete

These checks passed through fixtures and the bounded native follow-up: stack
placement, independent identities/bases, dirty inclusion, external-worktree
navigation, and `/new` detachment with reload and ordinary HEAD-based review.
Native picker and shared missing-Pi recovery remain untested in this slice.

- [x] Two successive tasks share a checkout but retain separate sessions and bases.
- [x] Dirty-file inclusion is explicit and preserves existing files.
- [x] External worktrees open without adoption.
- [x] Explicit cross-repository paths work from any cwd.
- [x] Ordinary Pi `/new` and `/review` remain usable without task registration.

### Zellij instruction rollout

This can proceed independently after the permissions contract is accepted:

- A long-running command starts as a new member of the existing bottom stack,
  without moving keyboard focus or changing the editor/agent area.
- Output can be read through the returned pane ID without focusing it.
- The persistent bottom shell, including busy processes or pending input, stays
  untouched. Neither an in-place replacement nor an additional split is used.
- Success and failure leave command output available in the stack; the shell
  survives throughout and needs no restoration.
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
live recovery, bottom-stack command placement, and proposed migration acceptance
checks remain distinct from those results.
