#!/usr/bin/env bash
set -euo pipefail

packages=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=packages/pi-task-state.sh
source "$packages/pi-task-state.sh"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Check GIT_AUTHOR_EMAIL=check@example.invalid
export GIT_COMMITTER_NAME=Check GIT_COMMITTER_EMAIL=check@example.invalid

reject() {
  if "$@" >"$tmp/rejected.log" 2>&1; then
    printf 'Expected failure: %s\n' "$*" >&2
    exit 1
  fi
}
assert_json() { jq -e "$1" "$2" >/dev/null; }
repo="$tmp/repo ' spaced"
git init -q "$repo"
printf 'initial\n' >"$repo/tracked"
printf 'delete me\n' >"$repo/deleted"
printf 'rename me\n' >"$repo/old name"
printf '*.ignored\n' >"$repo/.gitignore"
git -C "$repo" add .
git -C "$repo" commit -qm initial
head=$(git -C "$repo" rev-parse HEAD)
head_tree=$(git -C "$repo" rev-parse 'HEAD^{tree}')

clean="$repo/.git/pi-task/reviews/clean.json"
task_review_init "$repo" "$clean"
assert_json '.policy == "autonomous" and .adoption.choice == "clean" and .starting == .accepted and .starting == .adoption.snapshot' "$clean"
[ "$(jq -r '.starting.tree' "$clean")" = "$head_tree" ]
[ "$(stat -c %a "$clean")" = 600 ]
[ "$(stat -c %a "$(dirname "$clean")")" = 700 ]

printf 'staged\n' >"$repo/tracked"
git -C "$repo" add tracked
printf 'human working edit\n' >"$repo/tracked"
printf 'included despite ignore\n' >"$repo/staged.ignored"
git -C "$repo" add -f staged.ignored
printf 'do not capture\n' >"$repo/untracked.ignored"
printf '\000\001\377' >"$repo/binary"
printf 'odd filename\n' >"$repo/line
break"
ln -s tracked "$repo/link"
rm "$repo/deleted"
mv "$repo/old name" "$repo/new name"
index_before=$(sha256sum "$repo/.git/index")
status_before=$(GIT_OPTIONAL_LOCKS=0 git -C "$repo" status --porcelain=v1 --untracked-files=all)

include="$repo/.git/pi-task/reviews/include.json"
reject task_review_init "$repo" "$include"
grep -q -- '--adopt include' "$tmp/rejected.log"
[ ! -f "$include" ]
[ -z "$(git -C "$repo" for-each-ref --format='%(refname)' refs/pi-task/include/)" ]
task_review_init "$repo" "$include" guided include
assert_json '.policy == "guided" and .adoption.choice == "include" and .starting == .accepted and .starting != .adoption.snapshot' "$include"
[ "$(jq -r '.starting.tree' "$include")" = "$head_tree" ]
existing=$(jq -cS '.adoption.snapshot' "$include")
existing_tree=$(jq -r '.tree' <<<"$existing")
[ "$(git -C "$repo" show "$existing_tree:tracked")" = 'human working edit' ]
[ "$(git -C "$repo" show "$existing_tree:staged.ignored")" = 'included despite ignore' ]
reject git -C "$repo" cat-file -e "$existing_tree:untracked.ignored"
reject git -C "$repo" cat-file -e "$existing_tree:deleted"
[ "$(git -C "$repo" show "$existing_tree:new name")" = 'rename me' ]
[ "$(git -C "$repo" show "$existing_tree:line
break")" = 'odd filename' ]
[ "$(git -C "$repo" ls-tree "$existing_tree" link | cut -d ' ' -f 1)" = 120000 ]
git -C "$repo" show "$existing_tree:binary" >"$tmp/binary"
cmp "$tmp/binary" "$repo/binary"
[ "$(sha256sum "$repo/.git/index")" = "$index_before" ]
[ "$(GIT_OPTIONAL_LOCKS=0 git -C "$repo" status --porcelain=v1 --untracked-files=all)" = "$status_before" ]

trust="$repo/.git/pi-task/reviews/trust.json"
task_review_init "$repo" "$trust" '' trust
assert_json '.adoption.choice == "trust" and .starting == .accepted and .starting == .adoption.snapshot' "$trust"
starting=$(jq -cS '.starting' "$include")
adoption=$(jq -cS '.adoption' "$include")
task_review_init "$repo" "$include" autonomous
assert_json '.policy == "autonomous"' "$include"
[ "$(jq -cS '.starting' "$include")" = "$starting" ]
[ "$(jq -cS '.adoption' "$include")" = "$adoption" ]
reject task_review_init "$repo" "$include" guided trust
assert_json '.policy == "autonomous"' "$include"

# Committing must neither advance checkpoints nor hide already captured changes.
git -C "$repo" add -A
git -C "$repo" commit -qm 'agent commit midway'
task_review_init "$repo" "$include"
[ "$(jq -cS '.accepted' "$include")" = "$starting" ]
[ "$(task_snapshot "$repo" include)" = "$existing" ]
task_review_accept "$repo" "$include" "$existing"
[ "$(jq -cS '.accepted' "$include")" = "$existing" ]
[ "$(jq -cS '.starting' "$include")" = "$starting" ]
[ "$(jq -cS '.adoption' "$include")" = "$adoption" ]

printf 'accepted human edit\n' >>"$repo/tracked"
reject task_review_accept "$repo" "$include" "$existing"
grep -q 'worktree changed since reviewed snapshot' "$tmp/rejected.log"
[ "$(jq -cS '.accepted' "$include")" = "$existing" ]
human=$(task_snapshot "$repo" include)
task_review_accept "$repo" "$include" "$human"
[ "$(jq -cS '.accepted' "$include")" = "$human" ]
[ "$(jq -cS '.starting' "$include")" = "$starting" ]

# A Git ref, not session metadata or a reflog, owns each stored tree's lifetime.
git -C "$repo" reflog expire --expire=now --all
git -C "$repo" gc --prune=now --quiet
git -C "$repo" cat-file -e "$existing_tree:binary"
[ "$(git -C "$repo" rev-parse refs/pi-task/include/adopted-head)" = "$head" ]
[ "$(git -C "$repo" show "$(jq -r '.accepted.tree' "$include"):tracked")" = $'human working edit\naccepted human edit' ]

# Assume-unchanged cannot conceal edits; sparse entries fail rather than disappear.
git -C "$repo" update-index --assume-unchanged tracked
index_before=$(sha256sum "$repo/.git/index")
[ "$(task_snapshot "$repo" include)" = "$human" ]
[ "$(sha256sum "$repo/.git/index")" = "$index_before" ]
git -C "$repo" update-index --no-assume-unchanged tracked
git -C "$repo" update-index --skip-worktree tracked
reject task_snapshot "$repo" include
grep -q 'skip-worktree' "$tmp/rejected.log"
git -C "$repo" update-index --no-skip-worktree tracked

# Split indexes and separate worktree Git directories must remain untouched.
git -C "$repo" update-index --split-index
index_before=$(sha256sum "$repo/.git/index")
[ "$(task_snapshot "$repo" include)" = "$human" ]
[ "$(sha256sum "$repo/.git/index")" = "$index_before" ]
git -C "$repo" worktree add -q -b task/isolated "$tmp/isolated"
isolated="$repo/.git/pi-task/reviews/isolated.json"
task_review_init "$tmp/isolated" "$isolated" guided
assert_json '.adoption.choice == "clean"' "$isolated"
[ "$(jq -cS '.accepted' "$include")" = "$human" ]

race="$repo/.git/pi-task/reviews/race.json"
task_review_init "$tmp/isolated" "$race" guided &
first=$!
task_review_init "$tmp/isolated" "$race" autonomous &
second=$!
wait "$first"
wait "$second"
task_review_validate "$tmp/isolated" "$race"
assert_json '.starting == .accepted and .adoption.choice == "clean"' "$race"

blob=$(git -C "$tmp/isolated" rev-parse HEAD:tracked)
printf '0 %s\ttracked\n100644 %s 1\ttracked\n100644 %s 2\ttracked\n100644 %s 3\ttracked\n' \
  "$blob" "$blob" "$blob" "$blob" | git -C "$tmp/isolated" update-index --index-info
conflict_index=$(git -C "$tmp/isolated" rev-parse --path-format=absolute --git-path index)
index_before=$(sha256sum "$conflict_index")
reject task_snapshot "$tmp/isolated" conflict
grep -q 'resolve index conflicts' "$tmp/rejected.log"
[ "$(sha256sum "$conflict_index")" = "$index_before" ]
git -C "$tmp/isolated" reset -q HEAD

# Dirty nested submodules need content snapshots, not just parent gitlink hashes.
leaf="$tmp/leaf"
library="$tmp/library"
parent="$tmp/parent"
for dir in "$leaf" "$library" "$parent"; do
  git init -q "$dir"
  printf 'initial\n' >"$dir/content"
  git -C "$dir" add .
  git -C "$dir" commit -qm initial
done
git -C "$library" -c protocol.file.allow=always submodule add -q "$leaf" 'nested leaf'
git -C "$library" commit -qam nested
git -C "$parent" -c protocol.file.allow=always submodule add -q "$library" 'vendor library'
git -C "$parent" commit -qam library
git -C "$parent" -c protocol.file.allow=always submodule update --init --recursive -q
sub="$parent/vendor library"
printf 'human submodule edit\n' >"$sub/content"
printf 'nested edit\n' >"$sub/nested leaf/content"
printf '\000\377' >"$sub/new binary"
parent_index=$(sha256sum "$parent/.git/index")
sub_index=$(sha256sum "$(git -C "$sub" rev-parse --path-format=absolute --git-path index)")
sub_state="$parent/.git/pi-task/reviews/sub.json"
reject task_review_init "$parent" "$sub_state"
task_review_init "$parent" "$sub_state" '' include
assert_json '.starting.tree == .adoption.snapshot.tree and .starting.submodules != .adoption.snapshot.submodules' "$sub_state"
sub_tree=$(jq -r '.adoption.snapshot.submodules["vendor library"].tree' "$sub_state")
leaf_tree=$(jq -r '.adoption.snapshot.submodules["vendor library"].submodules["nested leaf"].tree' "$sub_state")
[ "$(git -C "$sub" show "$sub_tree:content")" = 'human submodule edit' ]
[ "$(git -C "$sub/nested leaf" show "$leaf_tree:content")" = 'nested edit' ]
[ "$(sha256sum "$parent/.git/index")" = "$parent_index" ]
[ "$(sha256sum "$(git -C "$sub" rev-parse --path-format=absolute --git-path index)")" = "$sub_index" ]
sub_current=$(task_snapshot "$parent" sub)
git -C "$parent" config diff.ignoreSubmodules all
task_snapshot_diff "$parent" "$(jq -cS '.accepted' "$sub_state")" "$sub_current" >"$tmp/submodule.diff"
grep -q '+human submodule edit' "$tmp/submodule.diff"
grep -q '+nested edit' "$tmp/submodule.diff"
grep -q 'Binary files' "$tmp/submodule.diff"
task_review_accept "$parent" "$sub_state" "$sub_current"
printf 'concurrent child edit\n' >>"$sub/nested leaf/content"
reject task_review_accept "$parent" "$sub_state" "$sub_current"
[ "$(jq -cS '.accepted' "$sub_state")" = "$sub_current" ]
git -C "$sub" gc --prune=now --quiet
git -C "$sub/nested leaf" gc --prune=now --quiet
git -C "$sub" cat-file -e "$sub_tree:new binary"
git -C "$sub/nested leaf" cat-file -e "$leaf_tree:content"

# Uninitialized submodules are represented explicitly, not mistaken for empty trees.
git -C "$parent" -c protocol.file.allow=always submodule --quiet deinit -f -- 'vendor library'
uninitialized=$(task_snapshot "$parent" uninitialized)
[ "$(jq -c '.submodules["vendor library"]' <<<"$uninitialized")" = null ]

# Unsupported/corrupt state is never silently replaced on reopening.
cp "$include" "$tmp/good.json"
jq '.version = 99' "$include" >"$tmp/bad.json"
cp "$tmp/bad.json" "$include"
reject task_review_init "$repo" "$include" guided
cmp "$tmp/bad.json" "$include"
cp "$tmp/good.json" "$include"
reject task_review_validate "$parent" "$include"

# Conditional callers suppress Bash errexit; failures must still preserve state.
mkdir -p "$tmp/blocked.json.lock"
reject task_review_init "$repo" "$tmp/blocked.json" guided trust
[ ! -f "$tmp/blocked.json" ]
reject task_review_accept "$repo" "$tmp/blocked.json" "$human"
cp "$include" "$tmp/save.json"
(
  # Called indirectly by task_review_save in the sourced helper.
  # shellcheck disable=SC2329
  printf() { return 1; }
  reject task_review_save "$tmp/save.json" '{"replacement": true}'
)
cmp "$include" "$tmp/save.json"

# Launcher adoption runs before any Zellij interaction; state inspection is read-only.
mkdir "$tmp/bin"
printf '#!/usr/bin/env bash\nprintf "unexpected Zellij call\\n" >&2\nexit 98\n' >"$tmp/bin/zellij"
chmod +x "$tmp/bin/zellij"
launcher_env=(env PATH="$tmp/bin:$PATH")
reject "${launcher_env[@]}" bash "$packages/pi-task.sh" --repo "$repo" open "$repo"
grep -q -- '--adopt include' "$tmp/rejected.log"
root_hash=$(printf '%s' "$repo" | sha256sum)
root_state="$repo/.git/pi-task/reviews/${root_hash:0:12}.json"
[ ! -f "$root_state" ]
task_review_init "$repo" "$root_state" guided trust
"${launcher_env[@]}" bash "$packages/pi-task.sh" --repo "$repo" state >"$tmp/shown.json"
cmp "$root_state" "$tmp/shown.json"
reject "${launcher_env[@]}" bash "$packages/pi-task.sh" --repo "$repo" state --review-mode autonomous
reject "${launcher_env[@]}" bash "$packages/pi-task.sh" --repo "$repo" new invalid --review-mode yolo
reject "${launcher_env[@]}" bash "$packages/pi-task.sh" --repo "$repo" new invalid --adopt trust

checkpoint="$repo/.git/pi-task/reviews/checkpoint.json"
task_review_init "$repo" "$checkpoint" autonomous trust
printf 'batch edit\n' >"$repo/tracked"
printf 'new file\n' >"$repo/checkpoint added"
printf '\000\002\376' >"$repo/binary"
mv "$repo/new name" "$repo/renamed again"
rm "$repo/link"

coproc WRITER { task_review_lease "$repo" "$checkpoint" writer; }
writer_pid=$!
IFS= read -r ready <&"${WRITER[0]}"
[ "$ready" = ready ]
task_review_begin "$repo" "$checkpoint" 'Behavior and rationale' 'Checks run/not run'
assert_json '.pending.snapshot == null' "$checkpoint"
reject task_review_lease "$repo" "$checkpoint" writer </dev/null
(task_review_prepare "$repo" "$checkpoint" >"$tmp/prepared.json") &
prepare_pid=$!
sleep 0.1
[ ! -s "$tmp/prepared.json" ]
printf 'in-flight shell edit\n' >"$repo/checkpoint added"
printf '\n' >&"${WRITER[1]}"
wait "$writer_pid"
wait "$prepare_pid"
assert_json '.pending.snapshot.tree != .accepted.tree' "$checkpoint"
id=$(jq -r '.pending.id' "$checkpoint")
task_review_command diff "$repo" "$checkpoint" >"$tmp/batch.diff"
grep -q 'in-flight shell edit' "$tmp/batch.diff"
grep -q 'Binary files' "$tmp/batch.diff"
grep -q 'rename from new name' "$tmp/batch.diff"
grep -q 'deleted file mode 120000' "$tmp/batch.diff"
reject task_review_resolve "$repo" "$checkpoint" stale accept

# Reopening and policy updates cannot clear the pause, nor accept unseen human edits.
task_review_init "$repo" "$checkpoint" guided
[ "$(jq -r '.pending.id' "$checkpoint")" = "$id" ]
printf 'human edit after opening\n' >>"$repo/tracked"
reject task_review_resolve "$repo" "$checkpoint" "$id" accept
assert_json '.pending != null and .accepted != .pending.snapshot' "$checkpoint"
task_review_prepare "$repo" "$checkpoint" >/dev/null
task_review_resolve "$repo" "$checkpoint" "$id" accept
assert_json '.pending == null and .accepted != .starting' "$checkpoint"
[ "$(tail -n1 "$repo/tracked")" = 'human edit after opening' ]

printf 'revision needed\n' >>"$repo/tracked"
task_review_begin "$repo" "$checkpoint" 'Revision' 'Checked'
task_review_prepare "$repo" "$checkpoint" >/dev/null
id=$(jq -r '.pending.id' "$checkpoint")
accepted=$(jq -cS '.accepted' "$checkpoint")
task_review_resolve "$repo" "$checkpoint" "$id" changes
[ "$(jq -cS '.accepted' "$checkpoint")" = "$accepted" ]
grep -q 'revision needed' "$repo/tracked"
task_review_begin "$repo" "$checkpoint" 'End-of-run' 'Checked'
task_review_prepare "$repo" "$checkpoint" >/dev/null
id=$(jq -r '.pending.id' "$checkpoint")
task_review_resolve "$repo" "$checkpoint" "$id" accept
task_review_begin "$repo" "$checkpoint" 'No change' 'Checked'
task_review_prepare "$repo" "$checkpoint" >"$tmp/unchanged.json"
assert_json '.pending == null' "$tmp/unchanged.json"
jq '.pending = {}' "$checkpoint" >"$tmp/corrupt-pending.json"
reject task_review_validate "$repo" "$tmp/corrupt-pending.json"

printf 'pi-task review: adoption, policy, snapshots, checkpoints, leases, acceptance, submodules, GC and launcher checks passed\n'
