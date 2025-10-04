{ pkgs, ... }:
let
  sops-mac =
    pkgs.writeShellScriptBin "sops-mac" # sh
      ''
        # Find the sops-nix-user script referenced by the current system
        sops_hash=$(nix-store -q --graph /run/current-system 2>/dev/null | grep -o '[a-z0-9]*-sops-nix-user' | head -n 1)

        if [ -z "$sops_hash" ]; then
          echo "Error: No sops-nix-user found in current system graph"
          exit 1
        fi

        sops_script="/nix/store/$sops_hash"

        if [ -z "$sops_script" ]; then
          echo "Error: No sops-nix-user script found in /nix/store"
          exit 1
        fi

        echo "Found sops-nix-user at: $sops_script"
        echo "Running sops-nix-user..."

        # Execute the found script with all passed arguments
        exec "$sops_script" "$@"
      '';

in
{
  home.packages = [
    sops-mac
  ];
}
