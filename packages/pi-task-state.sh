# Loaded by pi-task; private indexes keep snapshots independent of staging and commits.

task_review_fail() { printf 'pi-task review: %s\n' "$*" >&2; return 1; }

task_snapshot() (
  set -euo pipefail
  local root=$1 namespace=$2 commit=${3:-} tree index original entry info path child scratch gitdir
  local children='{}'
  gitdir=$(git -C "$root" rev-parse --absolute-git-dir) || exit 1
  scratch=$(mktemp -d "$gitdir/pi-task-snapshot.XXXXXX") || exit 1
  trap 'rm -rf -- "$scratch"' EXIT
  if [ -n "$commit" ]; then
    tree=$(git -C "$root" rev-parse --verify "${commit}^{tree}") || exit 1
  else
    index="$scratch/index"
    original=$(git -C "$root" rev-parse --path-format=absolute --git-path index) || exit 1
    if [ -f "$original" ]; then
      cp -- "$original" "$index" || exit 1
    else
      GIT_INDEX_FILE=$index git -C "$root" read-tree --empty || exit 1
    fi
    GIT_INDEX_FILE=$index git -C "$root" ls-files --unmerged >"$scratch/conflicts" || exit 1
    if [ -s "$scratch/conflicts" ]; then
      task_review_fail "resolve index conflicts before snapshotting $root"
      exit 1
    fi
    GIT_INDEX_FILE=$index git -C "$root" ls-files -v -z >"$scratch/flags" || exit 1
    if grep -zq '^[Ss] ' "$scratch/flags"; then
      task_review_fail "sparse/skip-worktree entries cannot be reviewed safely: $root"
      exit 1
    fi
    GIT_INDEX_FILE=$index git -C "$root" ls-files -z >"$scratch/paths" || exit 1
    GIT_INDEX_FILE=$index git -C "$root" -c core.splitIndex=false update-index --no-assume-unchanged -z --stdin <"$scratch/paths" || exit 1
    # Seed from the real index so explicitly staged ignored files are included too.
    GIT_INDEX_FILE=$index git -C "$root" -c core.splitIndex=false add --all -- . || exit 1
    tree=$(GIT_INDEX_FILE=$index git -C "$root" write-tree) || exit 1
  fi
  # A tree mentioned only in JSON would otherwise be eligible for Git GC.
  git -C "$root" update-ref "refs/pi-task/$namespace/$tree" "$tree" || exit 1
  git -C "$root" ls-tree -rz "$tree" >"$scratch/entries" || exit 1
  while IFS= read -r -d '' entry; do
    info=${entry%%$'\t'*}
    [ "${info%% *}" = 160000 ] || continue
    path=${entry#*$'\t'}
    child=null
    if [ -e "$root/$path/.git" ]; then
      if [ -n "$commit" ]; then
        child=$(task_snapshot "$root/$path" "$namespace" "${info##* }") || exit 1
      else
        child=$(task_snapshot "$root/$path" "$namespace") || exit 1
      fi
    fi
    children=$(jq -c --arg path "$path" --argjson child "$child" '. + {($path): $child}' <<<"$children") || exit 1
  done <"$scratch/entries"
  jq -cnS --arg tree "$tree" --argjson children "$children" '{tree: $tree, submodules: $children}'
)

task_review_validate() {
  jq -e --arg root "$1" '
    def snapshot:
      type == "object" and (.tree | type == "string" and test("^([0-9a-f]{40}|[0-9a-f]{64})$"))
      and (.submodules | type == "object" and all(.[]; . == null or snapshot));
    .version == 1 and .root == $root
    and (.policy == "autonomous" or .policy == "guided")
    and (.starting | snapshot) and (.accepted | snapshot)
    and (.pending == null or (.pending | type == "object"
      and (.id | type == "string" and length > 0)
      and (.summary | type == "string") and (.checks | type == "string")
      and (.snapshot == null or (.snapshot | snapshot))))
    and (.adoption.snapshot | snapshot)
    and (.adoption.choice == "clean" or .adoption.choice == "include" or .adoption.choice == "trust")
  ' "$2" >/dev/null || task_review_fail "invalid or unsupported review state: $2"
}

task_review_save() (
  set -euo pipefail
  local file=$1 json=$2 temporary
  temporary=$(mktemp "$file.XXXXXX") || exit 1
  trap 'rm -f -- "$temporary"' EXIT
  printf '%s\n' "$json" >"$temporary" || exit 1
  mv -- "$temporary" "$file" || exit 1
)

task_review_init() (
  set -euo pipefail
  local root=$1 file=$2 policy=${3:-} adopt=${4:-} lock status head existing starting json
  local namespace
  namespace=$(basename "$file" .json)
  case "$policy" in ''|autonomous|guided) ;; *) task_review_fail 'review mode must be autonomous or guided'; exit 1 ;; esac
  case "$adopt" in ''|include|trust) ;; *) task_review_fail 'adoption must be include or trust'; exit 1 ;; esac
  umask 077
  mkdir -p -- "$(dirname "$file")" || exit 1
  exec {lock}>"$file.lock" || exit 1
  flock "$lock" || exit 1
  if [ -f "$file" ]; then
    task_review_validate "$root" "$file" || exit 1
    [ -z "$adopt" ] || { task_review_fail 'worktree already adopted; --adopt cannot reset baselines'; exit 1; }
    if [ -n "$policy" ]; then
      json=$(jq --arg policy "$policy" '.policy = $policy' "$file") || exit 1
      task_review_save "$file" "$json" || exit 1
    fi
    exit 0
  fi
  head=$(git -C "$root" rev-parse --verify HEAD) || exit 1
  status=$(GIT_OPTIONAL_LOCKS=0 git -C "$root" status --porcelain=v1 --untracked-files=all --ignore-submodules=none) || exit 1
  if [ -n "$status" ] && [ -z "$adopt" ]; then
    task_review_fail 'existing edits need an explicit choice: --adopt include (review against HEAD) or --adopt trust (use current state as baseline)'
    exit 1
  fi
  existing=$(task_snapshot "$root" "$namespace") || exit 1
  starting=$(task_snapshot "$root" "$namespace" "$head") || exit 1
  if [ "$existing" != "$starting" ] && [ -z "$adopt" ]; then
    task_review_fail 'contents differ from HEAD despite status; choose --adopt include or --adopt trust'
    exit 1
  fi
  if [ "$adopt" = trust ]; then starting=$existing; fi
  git -C "$root" update-ref "refs/pi-task/$namespace/adopted-head" "$head" || exit 1
  json=$(jq -nS --arg root "$root" --arg policy "${policy:-autonomous}" \
    --arg choice "${adopt:-clean}" --arg head "$head" --arg status "$status" \
    --argjson existing "$existing" --argjson starting "$starting" '
    {version: 1, root: $root, policy: $policy, starting: $starting, accepted: $starting,
     adoption: {choice: $choice, head: $head, status: $status, snapshot: $existing}}
  ') || exit 1
  task_review_save "$file" "$json"
)

# Keep the expected-snapshot check for non-UI callers too.
task_review_accept() (
  set -euo pipefail
  local root=$1 file=$2 expected=$3 lock current json namespace
  namespace=$(basename "$file" .json)
  exec {lock}>"$file.lock" || exit 1
  flock "$lock" || exit 1
  task_review_validate "$root" "$file" || exit 1
  current=$(task_snapshot "$root" "$namespace") || exit 1
  if [ "$(jq -cS . <<<"$current")" != "$(jq -cS . <<<"$expected")" ]; then
    task_review_fail 'worktree changed since reviewed snapshot; review again before accepting'
    exit 1
  fi
  json=$(jq --argjson snapshot "$current" '.accepted = $snapshot' "$file") || exit 1
  task_review_save "$file" "$json"
)

# Locks account for cooperating tools, not unrelated shells or background daemons.
# A lease lives until its owner's stdin closes, including after Pi exits.
task_review_lease() (
  set -euo pipefail
  local root=$1 file=$2 kind=$3 lock metadata
  case "$kind" in
    writer)
      exec {lock}>"$file.writers" || exit 1
      flock -s "$lock" || exit 1
      exec {metadata}>"$file.lock" || exit 1
      flock "$metadata" || exit 1
      task_review_validate "$root" "$file" || exit 1
      jq -e '.pending == null' "$file" >/dev/null || { task_review_fail 'review pending; task writers paused'; exit 1; }
      flock -u "$metadata" || exit 1 ;;
    reviewer)
      exec {lock}>"$file.reviewer" || exit 1
      flock -n "$lock" || { task_review_fail 'review already open in another Pi'; exit 1; } ;;
    *) task_review_fail 'unknown lease kind'; exit 1 ;;
  esac
  printf 'ready\n'
  IFS= read -r _ || true
)

task_review_begin() (
  set -euo pipefail
  local root=$1 file=$2 summary=$3 checks=$4 lock json
  exec {lock}>"$file.lock" || exit 1
  flock "$lock" || exit 1
  task_review_validate "$root" "$file" || exit 1
  if jq -e '.pending != null' "$file" >/dev/null; then exit 0; fi
  json=$(jq --arg id "$(date +%s%N)-$BASHPID" --arg summary "$summary" --arg checks "$checks" \
    '.pending = {id: $id, summary: $summary, checks: $checks, snapshot: null}' "$file") || exit 1
  task_review_save "$file" "$json"
)

task_review_prepare() (
  set -euo pipefail
  local root=$1 file=$2 writers lock current json
  exec {writers}>"$file.writers" || exit 1
  flock "$writers" || exit 1
  exec {lock}>"$file.lock" || exit 1
  flock "$lock" || exit 1
  task_review_validate "$root" "$file" || exit 1
  jq -e '.pending != null' "$file" >/dev/null || { task_review_fail 'no pending review'; exit 1; }
  current=$(task_snapshot "$root" "$(basename "$file" .json)") || exit 1
  if [ "$current" = "$(jq -cS '.accepted' "$file")" ]; then
    json=$(jq 'del(.pending)' "$file") || exit 1
  else
    json=$(jq --argjson snapshot "$current" '.pending.snapshot = $snapshot' "$file") || exit 1
  fi
  task_review_save "$file" "$json" || exit 1
  printf '%s\n' "$json"
)

task_snapshot_diff() (
  set -euo pipefail
  local root=$1 before=$2 after=$3 label=${4:-.} path old new empty
  printf '\n=== %s ===\n' "$label"
  if [ ! -d "$root" ]; then
    printf 'Submodule unavailable: %s\n' "$label"
    exit 0
  fi
  empty=$(git -C "$root" mktree </dev/null) || exit 1
  old=$(jq -r --arg empty "$empty" '.tree // $empty' <<<"$before") || exit 1
  new=$(jq -r --arg empty "$empty" '.tree // $empty' <<<"$after") || exit 1
  git -C "$root" --no-pager -c core.quotePath=true diff --no-ext-diff --no-textconv --no-color \
    --find-renames --ignore-submodules=none --stat --summary "$old" "$new" -- || exit 1
  git -C "$root" --no-pager -c core.quotePath=true diff --no-ext-diff --no-textconv --no-color \
    --find-renames --ignore-submodules=none "$old" "$new" -- || exit 1
  while IFS= read -r path; do
    path=$(jq -r '. + "/"' <<<"$path") || exit 1
    path=${path%/}
    old=$(jq -cS --arg path "$path" '.submodules[$path] // null' <<<"$before") || exit 1
    new=$(jq -cS --arg path "$path" '.submodules[$path] // null' <<<"$after") || exit 1
    [ "$old" != "$new" ] || continue
    if [ ! -e "$root/$path/.git" ]; then
      printf '\nSubmodule unavailable: %s/%s (before: %s; after: %s)\n' "$label" "$path" "$old" "$new"
    else
      task_snapshot_diff "$root/$path" "$old" "$new" "$label/$path" || exit 1
    fi
  done < <(jq -cn --argjson a "$before" --argjson b "$after" \
    '[(($a.submodules // {}) | keys[]), (($b.submodules // {}) | keys[])] | unique[]')
)

task_review_resolve() (
  set -euo pipefail
  local root=$1 file=$2 id=$3 decision=$4 writers lock current json expected
  exec {writers}>"$file.writers" || exit 1
  flock "$writers" || exit 1
  exec {lock}>"$file.lock" || exit 1
  flock "$lock" || exit 1
  task_review_validate "$root" "$file" || exit 1
  [ "$(jq -r '.pending.id' "$file")" = "$id" ] || { task_review_fail 'stale review response'; exit 1; }
  case "$decision" in
    accept)
      expected=$(jq -cS '.pending.snapshot' "$file") || exit 1
      [ "$expected" != null ] || { task_review_fail 'review not prepared'; exit 1; }
      current=$(task_snapshot "$root" "$(basename "$file" .json)") || exit 1
      [ "$current" = "$expected" ] || { task_review_fail 'worktree changed; reopen review before accepting'; exit 1; }
      json=$(jq '.accepted = .pending.snapshot | del(.pending)' "$file") || exit 1 ;;
    changes) json=$(jq 'del(.pending)' "$file") || exit 1 ;;
    *) task_review_fail 'unknown review decision'; exit 1 ;;
  esac
  task_review_save "$file" "$json"
)

task_review_command() (
  set -euo pipefail
  local operation=${1:?} root=${2:?} file=${3:?}
  shift 3
  task_review_validate "$root" "$file" || exit 1
  case "$operation" in
    lease) task_review_lease "$root" "$file" "$@" ;;
    begin) task_review_begin "$root" "$file" "$@" ;;
    prepare) task_review_prepare "$root" "$file" ;;
    resolve) task_review_resolve "$root" "$file" "$@" ;;
    diff)
      task_snapshot_diff "$root" "$(jq -cS '.accepted' "$file")" "$(jq -cS '.pending.snapshot' "$file")" ;;
    *) task_review_fail 'unknown review operation'; exit 1 ;;
  esac
)
