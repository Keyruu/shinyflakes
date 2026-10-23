# Git owns contents; this file stores workflow state, Markdown, and delivery receipts.
task_review_fail() { printf 'pi-task review: %s\n' "$*" >&2; return 1; }

task_review_validate() {
  jq -se --arg root "$1" '
    def counter: type == "number" and . >= 0 and . <= 9007199254740991 and floor == .;
    def oid: type == "string" and test("^([0-9a-f]{40}|[0-9a-f]{64})$");
    length == 1 and (.[0] |
    .version == 2 and .root == $root and (.base | oid)
    and (.policy == "autonomous" or .policy == "guided")
    and (.generation | counter) and (.reviewedGeneration | counter)
    and .reviewedGeneration <= .generation
    and (.draft | type == "string") and (.draftVersion | counter)
    and (.pending == null or (.pending | type == "object"
      and (.id | type == "string" and length > 0)
      and (.summary | type == "string") and (.checks | type == "string")))
    and (.coordinator == null or (.coordinator | type == "string" and length > 0))
    and (.coordinatorSession == null or (.coordinator != null
      and (.coordinatorSession | type == "string" and startswith("/") and endswith(".jsonl"))))
    and (.submissions | type == "array" and all(.[];
      (.id | type == "string" and length > 0) and (.text | type == "string" and length > 0)
      and (.coordinator | type == "string" and length > 0)
      and (.kind == "question" or .kind == "changes") and (.delivered | type == "boolean")
      and (.draftVersion == null or (.draftVersion | counter)))))
  ' "$2" >/dev/null || task_review_fail "invalid/legacy review state: $2; legacy tasks require explicit migration with a committed --base"
}

# Pi may have started below the worktree root; still reject a different checkout.
task_review_session_cwd() {
  local root=$1 file=$2 id=$3 cwd
  [ -f "$file" ] || { task_review_fail 'session transcript unavailable'; return 1; }
  cwd=$(jq -er --arg id "$id" 'select(.type == "session" and .id == $id) | .cwd | strings' \
    <(head -n 1 -- "$file")) || { task_review_fail 'session transcript ID mismatch'; return 1; }
  if [ "$cwd" != "$root" ] &&
    [ "$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)" != "$root" ]; then
    task_review_fail 'session transcript checkout mismatch'; return 1
  fi
  printf '%s\n' "$cwd"
}

task_review_save() (
  set -euo pipefail
  local file=$1 json=$2 temporary
  umask 077
  temporary=$(mktemp "$file.XXXXXX") || exit 1
  trap 'rm -f -- "$temporary"' EXIT
  printf '%s\n' "$json" >"$temporary" || exit 1
  mv -- "$temporary" "$file" || exit 1
)

task_review_init() (
  set -euo pipefail
  local root=$1 file=$2 policy=${3:-} adopt=${4:-} base=${5:-HEAD} lock head status json
  case "$policy" in ''|autonomous|guided) ;; *) task_review_fail 'review mode must be autonomous or guided'; exit 1 ;; esac
  case "$adopt" in ''|include) ;; *) task_review_fail 'only --adopt include is supported; choose a committed --base instead of trusting dirty contents'; exit 1 ;; esac
  umask 077
  mkdir -p -- "$(dirname "$file")"
  exec {lock}>"$file.lock"; flock "$lock"
  if [ -f "$file" ]; then
    task_review_validate "$root" "$file"
    [ -z "$adopt" ] || { task_review_fail 'already adopted; cannot reset task base'; exit 1; }
    if [ -n "$policy" ]; then
      json=$(jq --arg policy "$policy" '.policy = $policy' "$file")
      task_review_save "$file" "$json"
    fi
    exit
  fi
  head=$(git -C "$root" rev-parse --verify --end-of-options "${base}^{commit}")
  status=$(GIT_OPTIONAL_LOCKS=0 git -C "$root" status --porcelain=v1 --untracked-files=all --ignore-submodules=none)
  if [ -n "$status" ] && [ -z "$adopt" ]; then
    task_review_fail 'existing edits need --adopt include; task base must be a commit'
    exit 1
  fi
  json=$(jq -nS --arg root "$root" --arg base "$head" --arg policy "${policy:-autonomous}" \
    --arg status "$status" '{version: 2, root: $root, base: $base, policy: $policy,
    generation: 0, reviewedGeneration: 0, draft: "", draftVersion: 0, submissions: [], adoptionStatus: $status}')
  task_review_save "$file" "$json"
)

task_review_migrate() (
  set -euo pipefail
  local root=$1 file=$2 base=$3 lock writers head json archive="$2.v1.json"
  exec {writers}>"$file.writers"; flock "$writers"
  exec {lock}>"$file.lock"; flock "$lock"
  jq -e --arg root "$root" '.version == 1 and .root == $root and (.policy == "autonomous" or .policy == "guided")' "$file" >/dev/null || {
    task_review_fail 'migration requires intact version-1 state'; exit 1;
  }
  [ ! -e "$archive" ] || { task_review_fail "legacy backup already exists: $archive"; exit 1; }
  head=$(git -C "$root" rev-parse --verify --end-of-options "${base}^{commit}")
  json=$(jq --arg base "$head" --arg archive "$archive" '
    {version: 2, root, policy, base: $base, generation: 0, reviewedGeneration: 0,
      coordinator, pending: (if .pending then {id: .pending.id, summary: .pending.summary, checks: .pending.checks} else null end),
      draft: ([.feedback.task // "", (.feedback.notes[]? |
        "## " + (.repository // ".") + "/" + .path + ":" + (.first|tostring) + "-" + (.last|tostring)
        + " (legacy " + .side + ", blob " + .blob + (if .resolved then ", resolved" else "" end)
        + (if .outdated then ", outdated" else "" end) + ")\n\n" + .text)] | map(select(length > 0)) | join("\n\n")),
      draftVersion: 0, submissions: [(.submissions // [])[] | . + {kind: "changes"}], legacyArchive: $archive}
  ' "$file")
  task_review_validate "$root" <(printf '%s\n' "$json")
  cp -p -- "$file" "$archive"
  task_review_save "$file" "$json"
  printf 'Migrated workflow only; legacy state and Git retention refs preserved. Backup: %s\n' "$archive"
)

# Only competing review UIs exclude each other; writers never acquire this lock.
task_review_lease() (
  set -euo pipefail
  local root=$1 file=$2 kind=$3 lock
  [ "$kind" = reviewer ] || { task_review_fail 'only reviewer leases are supported'; exit 1; }
  task_review_validate "$root" "$file"
  exec {lock}>"$file.reviewer"
  flock -n "$lock" || { task_review_fail 'review already open in another Pi'; exit 1; }
  printf 'ready\n'
  IFS= read -r _ || true
)

task_review_begin() (
  set -euo pipefail
  local root=$1 file=$2 summary=$3 checks=$4 base=${5:-} lock json
  exec {lock}>"$file.lock"; flock "$lock"
  task_review_validate "$root" "$file"
  if jq -e '.pending != null' "$file" >/dev/null; then exit; fi
  if [ -n "$base" ]; then base=$(git -C "$root" rev-parse --verify --end-of-options "${base}^{commit}"); fi
  json=$(jq --arg id "$(date +%s%N)-$BASHPID" --arg summary "$summary" --arg checks "$checks" --arg base "$base" \
    '.pending = {id: $id, summary: $summary, checks: $checks}
    | if $base != "" then .base = $base else . end' "$file")
  task_review_save "$file" "$json"
)

task_review_prepare() (
  set -euo pipefail
  local root=$1 file=$2 lock
  exec {lock}>"$file.lock"; flock "$lock"
  task_review_validate "$root" "$file"
  jq -e '.pending != null' "$file" >/dev/null || { task_review_fail 'no pending review'; exit 1; }
  jq . "$file"
)

task_review_update() (
  set -euo pipefail
  local operation=$1 root=$2 file=$3 lock json value text context id kind version
  shift 3
  exec {lock}>"$file.lock"; flock "$lock"
  task_review_validate "$root" "$file"
  case "$operation" in
    draft)
      version=$1 text=$2
      [ "$(jq -r '.draftVersion' "$file")" = "$version" ] || { task_review_fail 'draft changed in another editor; reopen draft before saving'; exit 1; }
      json=$(jq --rawfile text "$text" '.draft = $text | .draftVersion += 1' "$file") ;;
    append)
      json=$(jq --rawfile text "$1" '.draft += (if .draft == "" then "" else "\n\n" end) + $text | .draftVersion += 1' "$file") ;;
    submit)
      kind=$1 id=$2 text=${3:-} context=${4:-/dev/null}
      case "$kind" in question|changes) ;; *) exit 1 ;; esac
      if [ "$kind" = changes ]; then
        [ "$(jq -r '.pending.id' "$file")" = "$id" ] || { task_review_fail 'stale review'; exit 1; }
      fi
      jq -e '.coordinator != null' "$file" >/dev/null || { task_review_fail 'no coordinating Pi; start task Pi or use /review-coordinator'; exit 1; }
      if [ -n "$text" ]; then version=null
      else text=/dev/null; version=$(jq .draftVersion "$file"); fi
      json=$(jq --arg id "$(date +%s%N)-$BASHPID" --arg kind "$kind" \
        --rawfile supplied "$text" --rawfile context "$context" --argjson version "$version" '
        (if $version == null then $supplied else .draft end) as $notes
        | ($notes + (if $notes != "" and $context != "" then "\n\n" else "" end) + $context) as $text
        | if ($text | test("\\S")) then . else error("feedback is empty") end
        | .submissions += [{id: $id, coordinator: .coordinator, kind: $kind, draftVersion: $version, delivered: false,
          text: ("Review submission " + $id + " (" + $kind + "). Files and human edits kept.\n"
          + (if $kind == "question" then "Answer the question; review is optional and never pauses writers."
             else "Re-read files and preserve existing edits before revising; writers may have continued during review. When finished, summarize checks and use ask_user for follow-up. Do not request review approval." end)
          + "\n\n" + $text)}]
        | if $kind == "changes" then .reviewedGeneration = .generation | del(.pending) else . end
      ' "$file") ;;
    resolve)
      id=$1 value=$2
      [ "$value" = accept ] || { task_review_fail 'finish requires accept; use submit for changes'; exit 1; }
      [ "$(jq -r '.pending.id' "$file")" = "$id" ] || { task_review_fail 'stale review'; exit 1; }
      json=$(jq '.reviewedGeneration = .generation | del(.pending)' "$file") ;;
    bind|coordinate)
      id=$1; value=${2:-}
      if [ -n "$value" ]; then
        value=$(realpath -e -- "$value") || { task_review_fail 'session transcript unavailable'; exit 1; }
        task_review_session_cwd "$root" "$value" "$id" >/dev/null || exit 1
      fi
      if [ "$operation" = bind ]; then
        json=$(jq --arg id "$id" --arg path "$value" '
          .coordinator //= $id
          | if .coordinator == $id and $path != "" then .coordinatorSession = $path else . end' "$file")
      else
        json=$(jq --arg id "$id" --arg path "$value" '
          .coordinator = $id | .coordinatorSession = (if $path == "" then null else $path end)
          | (.submissions[] | select(.delivered == false)).coordinator = $id' "$file")
      fi ;;
    delivered)
      id=$1
      jq -e --arg id "$id" '.submissions | any(.id == $id)' "$file" >/dev/null || { task_review_fail 'unknown submission'; exit 1; }
      json=$(jq --arg id "$id" '
        (.submissions[] | select(.id == $id)) as $sent
        | if $sent.draftVersion != null and $sent.draftVersion == .draftVersion then .draft = "" | .draftVersion += 1 else . end
        | (.submissions[] | select(.id == $id)).delivered = true' "$file") ;;
    *) task_review_fail 'unknown review operation'; exit 1 ;;
  esac
  task_review_save "$file" "$json"
  printf '%s\n' "$json"
)

task_review_command() (
  set -euo pipefail
  local operation=${1:?} root=${2:?} file=${3:?}
  shift 3
  if [ "$operation" = migrate ]; then task_review_migrate "$root" "$file" "$@"; exit; fi
  if [ "$operation" = init ]; then
    if [ -f "$file" ]; then task_review_validate "$root" "$file"
    else task_review_init "$root" "$file" "" include HEAD; fi
    exit
  fi
  task_review_validate "$root" "$file"
  case "$operation" in
    lease) task_review_lease "$root" "$file" "$@" ;;
    begin) task_review_begin "$root" "$file" "$@" ;;
    begin-local) task_review_begin "$root" "$file" "$@" HEAD ;;
    prepare) task_review_prepare "$root" "$file" ;;
    *) task_review_update "$operation" "$root" "$file" "$@" ;;
  esac
)
