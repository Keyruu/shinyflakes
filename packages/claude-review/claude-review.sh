# claude-review — show an agent's working-tree changes in the sibling nvim
# pane (same zellij session) for review, and collect the user's feedback.
#
#   claude-review baseline              snapshot the working tree before editing
#   claude-review open [--incremental] [-- pathspec...]
#                                       open a review tab for changes since baseline
#   claude-review wait [seconds]        block until the review is finished, print feedback
#
# Snapshots are tree objects built with a throwaway index (`git add -A`), so
# untracked files are included and the user's real index is never touched.
# PLUGIN_LUA is prepended by package.nix.

shopt -s nullglob

die() {
  echo "claude-review: $*" >&2
  exit 1
}

root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
cd "$root"
state_dir="$(git rev-parse --absolute-git-dir)/claude-review"
mkdir -p "$state_dir"

snapshot() {
  local idx
  idx=$(mktemp)
  # Seed from the real index so `add -A` only hashes what changed. An empty
  # file is not a valid index, so drop it when there is nothing to copy.
  cp "$(git rev-parse --git-path index)" "$idx" 2>/dev/null || rm -f "$idx"
  GIT_INDEX_FILE=$idx git add -A
  GIT_INDEX_FILE=$idx git write-tree
  rm -f "$idx"
}

# Prints "<socket> <pane id>" of the nvim in this zellij session, preferring
# one whose cwd is the repo root, then the lowest pane id.
find_nvim() {
  if [[ -n ${CLAUDE_REVIEW_NVIM:-} ]]; then
    echo "$CLAUDE_REVIEW_NVIM -"
    return
  fi
  [[ -n ${ZELLIJ_SESSION_NAME:-} ]] || die "not in zellij; set CLAUDE_REVIEW_NVIM=<socket>"

  local best="" best_pane="" best_match=-1 s out sess pane cwd match
  for s in "${XDG_RUNTIME_DIR:-/tmp}"/nvim.*.0 "${XDG_RUNTIME_DIR:-/tmp}"/nvf.*.0; do
    [[ -S $s ]] || continue
    # shellcheck disable=SC2016 # vimscript env vars, expanded by nvim
    out=$(timeout 2 nvim --server "$s" --remote-expr \
      'join([$ZELLIJ_SESSION_NAME, $ZELLIJ_PANE_ID, getcwd()], "\n")' 2>/dev/null) || continue
    { read -r sess; read -r pane; read -r cwd; } <<<"$out" || true
    [[ $sess == "$ZELLIJ_SESSION_NAME" && -n $pane && $pane != "${ZELLIJ_PANE_ID:-}" ]] || continue
    match=0
    [[ $cwd == "$root" ]] && match=1
    if ((match > best_match)) || ((match == best_match && pane < best_pane)); then
      best=$s best_pane=$pane best_match=$match
    fi
  done
  [[ -n $best ]] || die "no nvim found in zellij session '$ZELLIJ_SESSION_NAME'"
  echo "$best $best_pane"
}

focus_pane() {
  [[ $1 != - && -n ${ZELLIJ_SESSION_NAME:-} ]] || return 0
  zellij action focus-pane-id "$1" >/dev/null 2>&1 || true
}

cmd_baseline() {
  snapshot >"$state_dir/baseline"
  rm -f "$state_dir/last"
  echo "baseline $(cat "$state_dir/baseline")"
}

cmd_open() {
  local base incremental=0
  while (($#)); do
    case $1 in
      --incremental) incremental=1 ;;
      --) shift; break ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done

  if ((incremental)) && [[ -s $state_dir/last ]]; then
    base=$(cat "$state_dir/last")
  elif [[ -s $state_dir/baseline ]]; then
    base=$(cat "$state_dir/baseline")
  else
    echo "claude-review: no baseline, reviewing against HEAD" >&2
    base=$(git rev-parse 'HEAD^{tree}')
  fi

  local proposed
  proposed=$(snapshot)
  local -a files
  mapfile -d '' -t files < <(git diff -z --name-only --no-renames "$base" "$proposed" -- "$@")
  if ((${#files[@]} == 0)); then
    echo "nothing changed since baseline"
    return 0
  fi

  local sock pane id payload response
  read -r sock pane < <(find_nvim)
  [[ -n ${sock:-} ]] || exit 1
  id="$(date +%s)-$$"
  payload="$state_dir/payload-$id.json"
  response="$state_dir/response-$id.json"
  rm -f "$state_dir"/payload-* "$state_dir"/response-*

  jq -n \
    --arg root "$root" --arg base "$base" --arg proposed "$proposed" \
    --arg response "$response" --arg title "${CLAUDE_REVIEW_TITLE:-}" \
    '{root: $root, base: $base, proposed: $proposed, response: $response,
      title: $title, files: $ARGS.positional}' \
    --args "${files[@]}" >"$payload"

  local res
  res=$(nvim --server "$sock" --remote-expr \
    "luaeval('dofile(_A[1]).open(_A[2])', ['$PLUGIN_LUA', '$payload'])") ||
    die "failed to reach nvim at $sock"
  [[ $res == ok ]] || die "nvim: $res"

  printf '%s\n' "$proposed" >"$state_dir/last"
  jq -n --arg response "$response" --arg proposed "$proposed" \
    --arg pane "$pane" --arg back "${ZELLIJ_PANE_ID:--}" \
    '{response: $response, proposed: $proposed, pane: $pane, back: $back}' \
    >"$state_dir/current.json"

  focus_pane "$pane"
  echo "review open in nvim (pane $pane): ${#files[@]} file(s)"
  printf '  %s\n' "${files[@]}"
}

cmd_wait() {
  local limit=${1:-3300}
  [[ -s $state_dir/current.json ]] || die "no open review"
  local response proposed back
  response=$(jq -r .response "$state_dir/current.json")
  proposed=$(jq -r .proposed "$state_dir/current.json")
  back=$(jq -r .back "$state_dir/current.json")

  local deadline=$((SECONDS + limit))
  until [[ -s $response ]]; do
    ((SECONDS < deadline)) || {
      echo "timeout: review still open after ${limit}s"
      exit 2
    }
    sleep 0.5
  done
  rm -f "$state_dir/current.json"
  focus_pane "$back"

  jq -r '
    "status: \(.status)",
    (if (.general // "") != "" then "overall: \(.general)" else empty end),
    (.comments // [] | if type == "array" then . else [] end
      | if length > 0 then "comments:" else empty end),
    (.comments // [] | if type == "array" then .[] else empty end
      | "- \(.file):\(.line)\(if .end_line != .line then "-\(.end_line)" else "" end)"
        + "\(if .side == "base" then " (old side)" else "" end)"
        + "\(if .source == "inline" then " [ai: comment]" else "" end): \(.text)"
        + "\(if (.code // "") != "" then "\n    > \(.code)" else "" end)")
  ' "$response"

  # Anything that differs from the snapshot taken at `open` is the user's
  # doing; inline ai: comments are already stripped by the nvim side.
  local now
  now=$(snapshot)
  if [[ $now != "$proposed" ]]; then
    echo
    echo "user edits during review (- agent's version, + user's version):"
    git diff --no-color "$proposed" "$now"
  fi
}

case ${1:-} in
  baseline) shift; cmd_baseline "$@" ;;
  open) shift; cmd_open "$@" ;;
  wait) shift; cmd_wait "$@" ;;
  *) die "usage: claude-review {baseline|open [--incremental] [-- pathspec...]|wait [seconds]}" ;;
esac
