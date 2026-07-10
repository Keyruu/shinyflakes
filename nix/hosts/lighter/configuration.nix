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
    inputs.nixos-hardware.nixosModules.tuxedo-infinitybook-pro14-gen10-amd
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko

    # inputs.lanzaboote.nixosModules.lanzaboote
    # flake.modules.nixos.secure-boot

    flake.modules.nixos.core
    flake.modules.nixos.workstation
    flake.modules.nixos.wayland
    flake.modules.nixos.laptop
    flake.modules.nixos.hibernation
    flake.modules.private.syncthing

    ./hardware-configuration.nix
    ./disk.nix
  ];

  user.name = "lucas";

  networking.nftables.enable = true;

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "/home/${config.user.name}/.config/sops/age/keys.txt";
  };

  services.tlp.enable = lib.mkForce false;

  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
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
    blueman.enable = true;
    libinput.enable = true;
  };

  services.mesh = {
    inherit (mesh.people.lucas.devices.lighter) ip;
    client = {
      enable = true;
      autostart = false;
      keyName = "lighterMeshKey";
      allowedIPs = [
        "192.168.100.0/24"
      ];
      ws = {
        enable = true;
        defaultInterface = "wlp0s20f3";
      };
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

  nix.package = lib.mkForce pkgs.lixPackageSets.stable.lix;

  nix.settings.trusted-users = [
    config.user.name
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.05";
}
