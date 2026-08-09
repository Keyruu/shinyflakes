{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "llms-to-epub";
  runtimeInputs = with pkgs; [
    curl
    gnused
    pandoc
    coreutils
  ];
  # Build an EPUB from a site's llms.txt (LLM-friendly single-markdown docs).
  # Many doc sites ship one: svelte.dev, etc. Lazier than crawling HTML.
  text = ''
    # usage: llms-to-epub <llms.txt-url> <name> [title]
    url="''${1:?usage: llms-to-epub <llms.txt-url> <name> [title]}"
    name="''${2:?need a name}"
    title="''${3:-$name}"
    dest="''${OUT_DIR:-$PWD}/$name.epub"
    md="$(mktemp --suffix=.md)"

    # Strip the <SYSTEM>...</SYSTEM> preamble these files carry.
    curl -sfL "$url" | sed 's|<SYSTEM>.*</SYSTEM>||' > "$md"

    pandoc "$md" -o "$dest" \
      --toc --toc-depth=1 --split-level=1 \
      --metadata title="$title" --metadata author='llms.txt'

    rm -f "$md"
    echo "built: $dest"
  '';
}
