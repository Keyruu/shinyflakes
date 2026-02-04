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
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
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
    ./modules
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;

  fileSystems."/home".neededForBoot = true;

  sops.secrets.carryallMeshKey = { };
  services.mesh.ip = mesh.people.lucas.devices.carryall.ip;
  networking = {
    hostName = lib.mkForce "PCL2025101301";
    firewall.allowedTCPPorts = [ 57621 ];
    firewall.allowedUDPPorts = [ 5353 ];
    wg-quick.interfaces = {
      "${mesh.interface}" = {
        address = [ "${mesh.ip}/24" ];
        privateKeyFile = config.sops.secrets.carryallMeshKey.path;
        dns = [ "100.67.0.2" ];
        autostart = false;

        peers = [
          {
            publicKey = "ctHXSXda0q3R/NjILCPkWzlJzMc9ekKKpNHpe2Avyh8=";
            allowedIPs = [
              mesh.subnet
              "192.168.100.0/24"
            ];
            endpoint = "mesh.peeraten.net:51234";
            persistentKeepalive = 25;
          }
        ];
      };
    };

  };

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

  # nixpkgs.config.packageOverrides = pkgs: {
  #   intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  # };
  # hardware.graphics = {
  #   enable = true;
  #   extraPackages = with pkgs; [
  #     intel-media-driver
  #     pkgs.intel-vaapi-driver.override
  #     { enableHybridCodec = true; } # For older Intel (fallback)
  #     libvdpau-va-gl
  #   ];
  # };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
