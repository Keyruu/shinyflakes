{
  inputs,
  flake,
  pkgs,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.quadlet-nix.nixosModules.quadlet

    flake.modules.nixos.hetzner
    flake.modules.nixos.core
    flake.modules.nixos.server
    flake.modules.nixos.locale
    flake.modules.nixos.nginx
    flake.modules.nixos.podman
    flake.modules.nixos.beszel-agent

    # Import local modules and services
    flake.modules.services.monitoring
    ./modules
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
      lokiAddress = "http://hati:3030";
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    busybox
    ethtool
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
