{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "rclone-obscure";
  runtimeInputs = with pkgs; [
    rclone
    sops
  ];
  text = ''
    if [ $# -ne 1 ]; then
      echo "Usage: rclone-obscure <webdav-password>" >&2
      echo "Obscures with rclone and stores as nzbdavWebdavPassword in nix/secrets.yaml" >&2
      exit 1
    fi

    if [ ! -f nix/secrets.yaml ]; then
      echo "Error: nix/secrets.yaml not found, run from the repo root" >&2
      exit 1
    fi

    obscured=$(rclone obscure "$1")
    sops set nix/secrets.yaml '["nzbdavWebdavPassword"]' "\"$obscured\""
    echo "Stored nzbdavWebdavPassword in nix/secrets.yaml" >&2
  '';
}
