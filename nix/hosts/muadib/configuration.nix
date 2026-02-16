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
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko

    #    inputs.lanzaboote.nixosModules.lanzaboote
    #    flake.modules.nixos.secure-boot

    flake.modules.nixos.core
    flake.modules.nixos.workstation
    flake.modules.nixos.wayland
    flake.modules.nixos.gaming
    flake.modules.nixos.syncthing

    ./hardware-configuration.nix
    ./disk.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;

  fileSystems."/home".neededForBoot = true;

  user.name = "lucas";

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "/home/${config.user.name}/.config/sops/age/keys.txt";
  };

  services.mesh = {
    inherit (mesh.people.lucas.devices.muadib) ip;
    client = {
      enable = true;
      ws = true;
      keyName = "muadibMeshKey";
    };
  };
  networking = {
    firewall = {
      interfaces."${mesh.interface}".allowedUDPPortRanges = [
        # hytale
        {
          from = 30000;
          to = 60000;
        }
      ];
      allowedTCPPorts = [
        57621
      ];
    };
  };

  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        options = "caps:escape";
      };
    };

    printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    fprintd.enable = true;
    blueman.enable = true;
    libinput.enable = true;
    tailscale.enable = true;
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
