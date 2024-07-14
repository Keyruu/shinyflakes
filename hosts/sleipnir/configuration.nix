{lib, modules, ...}: {
  imports = lib.flatten [
    (with modules; [
      docker
      hetzner
      locale
      nginx
      ssh-access
    ])
    ./headscale.nix
  ];

  networking.hostName = "sleipnir";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
