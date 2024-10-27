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
    ../../services/monitoring.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    secrets = {
      cloudflare.owner = "root";
    };
  };

  services.monitoring = {
    metrics = {
      enable = true;
      interface = "tailscale0";
    };
    logs = {
      enable = true;
      nginx = true;
      lokiAddress = "hati";
    };
  };

  networking.hostName = "sleipnir";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
