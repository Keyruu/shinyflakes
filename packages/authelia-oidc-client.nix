{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "authelia-oidc-client";
  runtimeInputs = with pkgs; [
    authelia
    sops
    coreutils
  ];
  text = ''
    if [ $# -ne 1 ]; then
      echo "Usage: authelia-oidc-client <service>" >&2
      echo "Generates <service>ClientSecret in nix/secrets.yaml and prints the pbkdf2 digest for the authelia client config." >&2
      exit 1
    fi

    if [ ! -f nix/secrets.yaml ]; then
      echo "Error: nix/secrets.yaml not found, run from the repo root" >&2
      exit 1
    fi

    key="$1ClientSecret"
    secret=$(head -c 48 /dev/urandom | base64 | tr -d '/+=' | head -c 48)

    sops set nix/secrets.yaml "[\"$key\"]" "\"$secret\""
    echo "Stored $key in nix/secrets.yaml" >&2

    echo "client_secret for authelia.nix:" >&2
    authelia crypto hash generate pbkdf2 --variant sha512 --password "$secret" | sed 's/^Digest: //'
  '';
}
