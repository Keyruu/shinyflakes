{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "forge-pr";
  runtimeInputs = with pkgs; [
    tea
    fzf
    gum
    jq
    xdg-utils
    coreutils
  ];
  # TUI over forgejo/gitea PRs via the official `tea` CLI. Repo + auth come from
  # `tea login` and the local git remote; override with `--repo owner/name`.
  #
  # The fzf preview re-invokes this script (FORGE_PR_PREVIEW=1) instead of an
  # inline jq command, so there is only one layer of shell quoting.
  text = ''
    # --- preview mode: print one PR's details, given the json file + index ---
    if [ "''${FORGE_PR_PREVIEW:-}" = "1" ]; then
      jq -r --arg i "$2" '
        .[] | select(.index == $i) |
        "# \(.title)\n" +
        "by \(.author)  ·  updated \(.updated)\n" +
        "ci: \(.ci // "none")   mergeable: \(.mergeable)\n\n" +
        (.body // "(no description)")
      ' "$1"
      exit 0
    fi

    repo_args=()
    loop=0
    while [ $# -gt 0 ]; do
      case "$1" in
        --repo|-r)
          [ -n "''${2:-}" ] || { echo "usage: forge-pr [--repo owner/name] [--loop]" >&2; exit 1; }
          repo_args=(--repo "$2"); shift 2 ;;
        --loop|-l) loop=1; shift ;;
        *) echo "usage: forge-pr [--repo owner/name] [--loop]" >&2; exit 1 ;;
      esac
    done

    prs="$(mktemp)"
    trap 'rm -f "$prs"' EXIT
    badge() { case "$1" in success) echo "✓";; failure|error) echo "✗";; pending) echo "•";; *) echo "?";; esac; }

    while true; do
      tea pr ls "''${repo_args[@]}" --state open \
        --fields index,title,body,author,updated,ci,mergeable,url -o json > "$prs"

      if [ "$(jq 'length' "$prs")" -eq 0 ]; then
        echo "no open pull requests"
        break
      fi

      # List line: hidden field 1 = bare index for the preview; visible columns
      # show a ci badge + title. ci is "" when no checks ran.
      index="$(jq -r '.[] | "\(.index)\t\(.ci // "none")\t\(.title)"' "$prs" \
        | while IFS=$'\t' read -r idx ci title; do
            printf '%s\t%s #%s  %s\n' "$idx" "$(badge "$ci")" "$idx" "$title"
          done \
        | fzf --with-nth=2.. --delimiter=$'\t' \
              --preview "FORGE_PR_PREVIEW=1 $0 $prs {1}" \
              --preview-window=right:60%:wrap \
        | cut -f1)"

      # Esc / no selection ends the session even in loop mode.
      [ -n "$index" ] || break

      action="$(gum choose --header "PR #$index" rebase "open in browser" skip)"
      case "$action" in
        "open in browser")
          xdg-open "$(jq -r --arg i "$index" '.[] | select(.index==$i) | .url' "$prs")"
          ;;
        rebase)
          # Gate: refuse to merge a PR that is not green + mergeable without an
          # explicit override, so a broken PR can't slip through.
          ci="$(jq -r --arg i "$index" '.[] | select(.index==$i) | .ci // ""' "$prs")"
          mergeable="$(jq -r --arg i "$index" '.[] | select(.index==$i) | .mergeable' "$prs")"
          if [ "$ci" != "success" ] || [ "$mergeable" != "true" ]; then
            gum style --foreground 196 \
              "⚠ PR #$index is not safe to merge (ci: ''${ci:-none}, mergeable: $mergeable)"
            if ! gum confirm --default=no "Merge anyway?"; then
              if [ "$loop" = 1 ]; then continue; else break; fi
            fi
          fi

          if gum confirm "tea pr merge --style rebase $index ?"; then
            tea pr merge "''${repo_args[@]}" --style rebase "$index"
          fi
          ;;
      esac

      [ "$loop" = 1 ] || break
    done
  '';
}
