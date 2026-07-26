{
  imports = [
    ./monitoring
    ./stacks

    ./cert.nix
    ./cockpit.nix
    ./disk-config.nix
    # ./gpu.nix
    ./nas.nix
    ./network.nix
    ./nginx.nix
    ./samba.nix
    ./adguard.nix
    ./copyparty.nix
    ./syncthing.nix
    ./backup.nix
    ./mesh.nix
    ./glance.nix
    ./forgejo-notify.nix
    ./forgejo-runner.nix
    ./renovate.nix
    ./harmonia.nix
    ./print.nix
  ];
}
