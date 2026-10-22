# Open the current worktree's changes in a foot window: Neovim + Diffview
# against the merge-base with origin/HEAD (or the ref given as $1).
# foot instead of an Orca tab: Orca's renderer can't keep up with full-screen nvim redraws.

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
  echo "usage: orca-diff [base-ref]   (default: merge-base of HEAD and origin/HEAD)"
  exit 0
fi

root=$(git rev-parse --show-toplevel)
head=$(git -C "$root" rev-parse HEAD)

if [[ -n ${1:-} ]]; then
  base=$(git -C "$root" rev-parse --verify "$1^{commit}")
else
  upstream=$(git -C "$root" symbolic-ref -q --short refs/remotes/origin/HEAD || echo origin/main)
  base=$(git -C "$root" merge-base HEAD "$upstream")
fi

if [[ $base == "$head" ]]; then
  # Nothing committed on top of base: plain DiffviewOpen also lists untracked files.
  cmd=(nvim +DiffviewOpen)
else
  cmd=(nvim "+DiffviewOpen $base")
  untracked=$(git -C "$root" ls-files --others --exclude-standard | wc -l)
  if ((untracked > 0)); then
    echo "note: $untracked untracked file(s) are hidden; register them with: git add -N <path>" >&2
  fi
fi

title="diff: $(basename "$root")"
# footclient needs a running foot server; fall back to a standalone foot.
footclient -N -T "$title" -D "$root" "${cmd[@]}" 2>/dev/null ||
  setsid -f foot -T "$title" -D "$root" "${cmd[@]}" >/dev/null 2>&1
