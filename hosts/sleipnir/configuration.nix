{
  lib,
  modules,
  pkgs,
  ...
}: {
  imports = lib.flatten [
    (with modules; [
      docker
      hetzner
      locale
      nginx
      ssh-access
    ])
    ./headscale.nix
    ./proxy-keyruu.nix
    ./nginx.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    secrets = {
      cloudflare.owner = "root";
    };
  };

  networking.hostName = "sleipnir";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
