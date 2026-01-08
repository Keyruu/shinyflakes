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
    # flake.modules.nixos.nginx
    flake.modules.nixos.podman
    flake.modules.nixos.beszel-agent
    flake.modules.nixos.caddy

    flake.modules.services.monitoring
    ./modules
  ];

  sops = {
    secrets = {
      cloudflare.owner = "root";
    };
  };

  services = {
    mesh.server.enable = true;
    monitoring = {
      metrics = {
        enable = true;
        interface = "portal0";
      };
      logs = {
        enable = true;
        instance = "100.67.0.1";
        lokiAddress = "http://100.67.0.2:3030";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    busybox
    ethtool
    dsnet
    kanidm
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
