{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "mdbook-to-epub";
  runtimeInputs = with pkgs; [
    git
    mdbook-epub
    gnused
    gnugrep
    findutils
    coreutils
  ];
  # Clone an mdBook repo and build an EPUB for Kobo/KOReader.
  # Uses mdbook-epub standalone mode: nixpkgs mdbook-epub is ABI-incompatible
  # with the plugin handshake of a newer mdbook, but standalone reads book.toml
  # directly and works.
  text = ''
    # usage: mdbook-to-epub <git-url> [name]
    url="''${1:?usage: mdbook-to-epub <git-url> [name]}"
    name="''${2:-$(basename "$url" .git)}"
    dest_dir="''${OUT_DIR:-$PWD}"
    work="$(mktemp -d)"

    git clone --depth 1 "$url" "$work/src"
    cd "$work/src"

    # Find book.toml (some repos nest it).
    root="$(dirname "$(find . -name book.toml -not -path '*/node_modules/*' | head -1)")"
    cd "$root"

    # Old mdbook crate in nixpkgs mdbook-epub rejects edition 2024.
    sed -i '/^edition = "2024"/d' book.toml
    grep -q '^\[output.epub\]' book.toml || printf '\n[output.epub]\n' >> book.toml

    mdbook-epub --standalone true .

    out="$(find book/epub -name '*.epub' | head -1)"
    dest="$dest_dir/$name.epub"
    cp "$out" "$dest"
    rm -rf "$work"
    echo "built: $dest"
  '';
}
