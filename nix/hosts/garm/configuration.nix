{
  lib,
  inputs,
  flake,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops

    flake.modules.nixos.core
    flake.modules.nixos.server
    flake.modules.nixos.locale
    flake.modules.nixos.nginx
    flake.modules.nixos.beszel-agent

    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")

    # Import local modules and services
    ./modules
    flake.modules.services.monitoring
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "24.05";

  # Override raspberry-pi-3 module's kernel packages
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    secrets = {
      cloudflare.owner = "root";
      headscaleAuthKey.owner = "root";
    };
  };

  networking = {
    networkmanager.enable = true;
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
    busybox
    libraspberrypi
    raspberrypi-eeprom
  ];
}
