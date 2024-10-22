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
      ssh-access
    ])
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    ./sdcard.nix
    ./printing.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "24.05";

  networking = {
    hostName = "garm";

    networkmanager.enable = true;
  };

  environment.systemPackages = with pkgs; [
    busybox
    libraspberrypi
    raspberrypi-eeprom
  ];
}
