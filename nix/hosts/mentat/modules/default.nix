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
    ./sirberus.nix
    ./adguard.nix
    ./copyparty.nix
    ./syncthing.nix
    ./backup.nix
    ./mesh.nix
    ./glance.nix
    ./forgejo-runner.nix
    ./renovate.nix
    ./nix-serve.nix
  ];
}
