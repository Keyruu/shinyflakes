{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "zfs-unlock";
  runtimeInputs = with pkgs; [
    zfs
    systemd
  ];
  text = ''
    if [ "$(id -u)" -ne 0 ]; then
      echo "Error: must run as root"
      exit 1
    fi

    echo "Unlocking ZFS encrypted datasets..."
    zfs load-key -a

    echo "Mounting all ZFS datasets..."
    zfs mount -a

    echo "Starting zfs-encrypted.target..."
    systemctl start zfs-encrypted.target

    echo "Done. Encrypted datasets are unlocked and services are starting."
  '';
}
