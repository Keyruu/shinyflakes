{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "update-hash";
  runtimeInputs = with pkgs; [
    git
    gnused
    nix
  ];
  text = ''
    pkgName="''${1:-}"
    if [ -z "$pkgName" ]; then
      echo "Usage: update-hash <package-name>"
      exit 1
    fi

    file="nix/packages/''${pkgName}.nix"

    if [ ! -f "$file" ]; then
      echo "File not found: $file"
      exit 1
    fi

    # Extract current rev from the file to find sibling updates
    currentRev=$(grep -oP 'rev\s*=\s*"\K[a-f0-9]{40}' "$file")
    if [ -z "$currentRev" ]; then
      echo "No rev found in $file"
      exit 1
    fi

    # Find all other packages sharing the same rev (same dependency group).
    # Handles cases like raycast extensions where multiple packages track
    # the same upstream rev but need individual hashes due to sparseCheckout
    # fetching different subdirectories.
    siblings=("$file")
    for other in nix/packages/*.nix; do
      if [ "$other" != "$file" ] && grep -q "rev\s*=\s*\"$currentRev\"" "$other"; then
        siblings+=("$other")
      fi
    done

    echo "Updating hashes for ''${#siblings[@]} package(s) sharing rev $currentRev"

    fakeHash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    for f in "''${siblings[@]}"; do
      name=$(basename "$f" .nix)
      echo "==> Processing: $name"

      sed -i "s|hash = \"[^\"]*\"|hash = \"$fakeHash\"|" "$f"

      output=$(nix build ".#$name" 2>&1) || true

      correctHash=$(echo "$output" | grep 'got:' | grep -o 'sha256-[A-Za-z0-9+/=]*')

      if [ -z "$correctHash" ]; then
        echo "    Build failed for $name, restoring hash and continuing"
        echo "$output" | tail -5
        continue
      fi

      sed -i "s|hash = \"[^\"]*\"|hash = \"$correctHash\"|" "$f"
      echo "    $name: $correctHash"
    done

    echo "Done."
  '';
}
