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

    file="packages/''${pkgName}.nix"

    if [ ! -f "$file" ]; then
      echo "File not found: $file"
      exit 1
    fi

    # Find sibling packages sharing the same rev (same dependency group).
    # Handles cases like raycast extensions where multiple packages track
    # the same upstream rev but need individual hashes due to sparseCheckout
    # fetching different subdirectories.
    siblings=("$file")
    currentRev=$(grep -oP 'rev\s*=\s*"\K[a-f0-9]{40}' "$file" 2>/dev/null || true)
    if [ -n "$currentRev" ]; then
      for other in packages/*.nix; do
        if [ "$other" != "$file" ] && grep -q "rev\s*=\s*\"$currentRev\"" "$other"; then
          siblings+=("$other")
        fi
      done
    fi

    echo "Updating hashes for ''${#siblings[@]} package(s)"

    fakeHash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    # fixHash <file> <attr> <build target>: fake the attr, build, write back the real hash
    fixHash() {
      local f="$1" attr="$2" target="$3"
      local originalHash output correctHash
      originalHash=$(grep -oP "\b$attr\s*=\s*\"\K[^\"]*" "$f" | head -1)

      sed -i "s|\b$attr = \"[^\"]*\"|$attr = \"$fakeHash\"|" "$f"

      output=$(nix build --no-link ".#$target" 2>&1) || true

      correctHash=$(echo "$output" | grep 'got:' | grep -o 'sha256-[A-Za-z0-9+/=]*' || true)

      if [ -z "$correctHash" ]; then
        echo "    Build failed for $target, restoring $attr and continuing"
        sed -i "s|\b$attr = \"[^\"]*\"|$attr = \"$originalHash\"|" "$f"
        echo "$output" | tail -5
        return
      fi

      sed -i "s|\b$attr = \"[^\"]*\"|$attr = \"$correctHash\"|" "$f"
      echo "    $target $attr: $correctHash"
    }

    for f in "''${siblings[@]}"; do
      name=$(basename "$f" .nix)
      echo "==> Processing: $name"

      fixHash "$f" hash "$name"
      # npm deps hash depends on the source, so it must be fixed after `hash`
      if grep -q '\bnpmDepsHash\s*=' "$f"; then
        fixHash "$f" npmDepsHash "$name.npmDeps"
      fi
    done

    echo "Done."
  '';
}
