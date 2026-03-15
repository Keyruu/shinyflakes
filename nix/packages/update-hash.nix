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

    output=$(nix build ".#''${pkgName}" 2>&1) && exit_code=0 || exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
      echo "Hash is already correct"
      exit 0
    fi

    correctHash=$(echo "$output" | grep 'got:' | grep -o 'sha256-[A-Za-z0-9+/=]*')

    if [ -z "$correctHash" ]; then
      echo "Build failed for reasons other than hash mismatch"
      exit 1
    fi

    sed -i "s|hash = \"[^\"]*\"|hash = \"$correctHash\"|" "$file"
    echo "Updated hash to: $correctHash"
  '';
}
