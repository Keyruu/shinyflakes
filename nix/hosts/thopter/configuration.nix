{
  inputs,
  flake,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.services) mesh;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga-7th-gen
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko

    inputs.lanzaboote.nixosModules.lanzaboote
    flake.modules.nixos.secure-boot

    flake.modules.nixos.core
    flake.modules.nixos.workstation
    flake.modules.nixos.wayland
    flake.modules.nixos.laptop
    flake.modules.nixos.hibernation
    flake.modules.nixos.syncthing

    ./hardware-configuration.nix
    ./disk.nix
  ];

  user.name = "lucas";

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "/home/${config.user.name}/.config/sops/age/keys.txt";
  };

  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        options = "caps:escape";
      };
    };

    printing.enable = true;

    fprintd = {
      enable = true;
      tod.enable = true;
      package = pkgs.fprintd;
      tod.driver = pkgs.libfprint-2-tod1-goodix;
    };

    blueman.enable = true;
    libinput.enable = true;
    tailscale.enable = false;
  };

  services.mesh = {
    inherit (mesh.people.lucas.devices.thopter) ip;
    client = {
      enable = true;
      keyName = "thopterMeshKey";
      allowedIPs = [
        "192.168.100.0/24"
      ];
      ws = true;
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

  programs = {
    firefox.enable = true;
    ydotool.enable = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
