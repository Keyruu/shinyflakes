{
  inputs,
  flake,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko

    inputs.lanzaboote.nixosModules.lanzaboote
    flake.modules.nixos.secure-boot

    flake.modules.nixos.core
    flake.modules.nixos.workstation
    flake.modules.nixos.wayland
    flake.modules.nixos.laptop
    flake.modules.nixos.hibernation

    ./hardware-configuration.nix
    ./disk.nix
    ./modules
  ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "/home/lucas/.config/sops/age/keys.txt";
  };

  fileSystems."/home".neededForBoot = true;

  networking.hostName = lib.mkForce "PCL2025101301";
  user.name = "lucas";

  networking.firewall.allowedTCPPorts = [ 57621 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      options = "caps:escape";
    };
  };

  # Faster rebuilding
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    dev.enable = false;
    info.enable = false;
    nixos.enable = false;
  };

  services.printing.enable = true;

  programs.fish.enable = true;

  users.users.lucas = {
    isNormalUser = true;
    description = "Lucas";
    extraGroups = [
      "networkmanager"
      "wheel"
      "ydotool"
      "docker"
      "disk"
    ];
    shell = pkgs.fish;
  };

  nixpkgs.config.allowUnfree = true;

  nix.package = lib.mkForce pkgs.lixPackageSets.stable.lix;

  nix.settings.trusted-users = [
    config.user.name
  ];

  services.fprintd.enable = true;

  services.blueman.enable = true;
  services.libinput.enable = true;

  services.tailscale.enable = true;

  programs = {
    firefox.enable = true;
    ydotool.enable = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
