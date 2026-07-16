{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "authelia-user-hash";
  runtimeInputs = with pkgs; [
    authelia
    sops
  ];
  text = ''
    if [ $# -ne 1 ]; then
      echo "Usage: authelia-user-hash <user>" >&2
      echo "Prompts for a password and stores its argon2 digest as <user>PasswordHash in nix/secrets.yaml." >&2
      exit 1
    fi

    if [ ! -f nix/secrets.yaml ]; then
      echo "Error: nix/secrets.yaml not found, run from the repo root" >&2
      exit 1
    fi

    key="$1PasswordHash"

    read -rs -p "Password: " password
    echo >&2
    read -rs -p "Confirm: " confirm
    echo >&2

    if [ "$password" != "$confirm" ]; then
      echo "Error: passwords do not match" >&2
      exit 1
    fi

    hash=$(authelia crypto hash generate argon2 --password "$password" | sed 's/^Digest: //')

    sops set nix/secrets.yaml "[\"$key\"]" "\"$hash\""
    echo "Stored $key in nix/secrets.yaml" >&2
  '';
}
