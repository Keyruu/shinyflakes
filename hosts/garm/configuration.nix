{
  lib,
  inputs,
  pkgs,
  modules,
  modulesPath,
  ...
}: {
  imports = lib.flatten [
    (with modules; [
      locale
      nginx
      ssh-access
    ])
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    ./sdcard.nix
    ./printing.nix
    ./adguard.nix
    ./network.nix
    ../../services/monitoring.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "24.05";

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    secrets = {
      cloudflare.owner = "root";
    };
  };


  networking = {
    hostName = "garm";

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
