set -euo pipefail

fail() { printf 'pi-task-linear: %s\n' "$*" >&2; exit 1; }
usage() {
  printf '%s\n' \
    'pi-task-linear [--all] [--repo DIR] [--base REF] [--review-mode autonomous|guided] [--model PATTERN]' \
    'Pick an assigned unfinished Linear ticket and start a Pi task. --all includes other assignees.' \
    "Key: LINEAR_API_KEY or \$XDG_CONFIG_HOME/pi-task/linear-api-key (default ~/.config)." \
    'Create a read-only personal API key: https://linear.app/settings/account/security'
}

all=false
args=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --all) all=true; shift ;;
    --repo|--base|--review-mode|--model)
      [ "$#" -ge 2 ] && [ -n "$2" ] || fail "$1 needs a value"
      case "$1" in
        --review-mode) case "$2" in autonomous|guided) ;; *) fail 'review mode must be autonomous or guided' ;; esac ;;
      esac
      args+=("$1" "$2"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown argument: $1" ;;
  esac
done
[ -z "${PI_TASK_ROOT:-}" ] || fail 'already inside a Pi task; run from the target repository instead'

key=${LINEAR_API_KEY:-}
key_file="${XDG_CONFIG_HOME:-$HOME/.config}/pi-task/linear-api-key"
if [ -z "$key" ] && [ -f "$key_file" ]; then key=$(<"$key_file"); fi
[ -n "$key" ] || fail "set LINEAR_API_KEY or save a read-only personal API key in $key_file; create one at https://linear.app/settings/account/security"
[[ ! "$key" =~ [[:cntrl:]] ]] || fail 'API key must be one line without control characters'

umask 077
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir "$tmp/previews"
: >"$tmp/issues.jsonl"
fields='nodes { identifier title description url state { name } } pageInfo { hasNextPage endCursor }'
connection="issues(first: 100, after: \$after, orderBy: updatedAt, filter: { state: { type: { nin: [\"completed\", \"canceled\"] } } }) { $fields }"
if "$all"; then
  query="query Issues(\$after: String) { $connection }"
else
  query="query Issues(\$after: String) { viewer { issues: assignedIssues${connection#issues} } }"
fi
cursor=""
printf 'Fetching unfinished Linear tickets…\n' >&2
while :; do
  payload=$(jq -cn --arg query "$query" --arg cursor "$cursor" \
    '{query: $query, variables: {after: (if $cursor == "" then null else $cursor end)}}')
  # Keep credentials out of process arguments and temporary files.
  printf 'Authorization: %s\n' "$key" | curl --fail --silent --show-error \
    --connect-timeout 10 --max-time 60 --header @- --header 'Content-Type: application/json' \
    --data "$payload" --output "$tmp/response.json" https://api.linear.app/graphql \
    || fail 'Linear request failed; check API key, permissions and network'
  jq -e 'type == "object"' "$tmp/response.json" >/dev/null || fail 'invalid Linear response'
  if jq -e '(.errors // []) | length > 0' "$tmp/response.json" >/dev/null; then
    jq -r '.errors[].message' "$tmp/response.json" >&2
    fail 'Linear returned GraphQL errors; no task created'
  fi
  jq '.data.viewer.issues // .data.issues' "$tmp/response.json" >"$tmp/page.json"
  jq -e '
    (.nodes | type == "array") and
    all(.nodes[];
      (.identifier | type == "string" and test("^[A-Za-z0-9][A-Za-z0-9._-]*$")) and
      (.title | type == "string") and (.url | type == "string") and
      (.description == null or (.description | type == "string")) and
      (.state.name | type == "string")) and
    (.pageInfo.hasNextPage | type == "boolean") and
    (if .pageInfo.hasNextPage then (.pageInfo.endCursor | type == "string" and length > 0) else true end)
  ' "$tmp/page.json" >/dev/null || fail 'incomplete Linear issue response'
  jq -c '.nodes[]' "$tmp/page.json" >>"$tmp/issues.jsonl"
  if ! jq -e '.pageInfo.hasNextPage' "$tmp/page.json" >/dev/null; then break; fi
  next=$(jq -r '.pageInfo.endCursor' "$tmp/page.json")
  [ "$next" != "$cursor" ] || fail 'Linear pagination cursor did not advance'
  cursor=$next
done
unset key LINEAR_API_KEY
jq -s '.' "$tmp/issues.jsonl" >"$tmp/issues.json"
if ! jq -e 'length > 0' "$tmp/issues.json" >/dev/null; then
  printf 'No unfinished tickets found. Try --all to include other assignees.\n'
  exit 0
fi
jq -r 'to_entries[] | [.key, .value.identifier, .value.state.name, .value.title]
  | map(tostring | gsub("[\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}]"; " ")) | join("\t")' \
  "$tmp/issues.json" >"$tmp/rows"
while IFS=$'\t' read -r index preview; do
  printf '%s' "$preview" | base64 --decode >"$tmp/previews/$index"
done < <(jq -r 'to_entries[] | [.key, (.value
  | "\(.identifier): \(.title)\n\(.state.name)\n\(.url)\n\n\(.description // "(No description.)")"
  | split("\n") | map(gsub("[\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}]"; " ")) | join("\n") | @base64)]
  | @tsv' "$tmp/issues.json")
export PI_LINEAR_PREVIEWS="$tmp/previews"
status=0
selected=$(fzf --no-multi --delimiter=$'\t' --with-nth=2.. --prompt='Linear ticket > ' \
  --preview="cat -- \"\$PI_LINEAR_PREVIEWS\"/{1}" --preview-window='right:60%:wrap' <"$tmp/rows") || status=$?
case "$status" in
  0) ;;
  1|130) exit 0 ;;
  *) fail "fzf failed (exit $status)" ;;
esac
index=${selected%%$'\t'*}
[[ "$index" =~ ^[0-9]+$ ]] || fail 'invalid picker selection'
jq -e --argjson index "$index" '.[$index] != null' "$tmp/issues.json" >/dev/null || fail 'unknown picker selection'
name=$(jq -r --argjson index "$index" '.[$index] | "\(.identifier)-\(.title)"
  | ascii_downcase | gsub("[^a-z0-9]+"; "-") | .[:80] | rtrimstr("-")' "$tmp/issues.json")
request=$(jq -r --argjson index "$index" '.[$index]
  | "\(.identifier): \(.title)\n\(.url)\n\n\(.description // "(No description.)")"' "$tmp/issues.json")
rm -rf -- "$tmp"
trap - EXIT
unset PI_LINEAR_PREVIEWS
exec pi-task new "$name" --request "$request" --model qwen-token-plan/glm-5.3 "${args[@]}"
