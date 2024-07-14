{ modules, pkgs, hostname, sops, lib, ... }:
{
  imports = lib.flatten [
    (with modules; [
      docker
      locale
      lvm-disk
      nginx
      ssh-access
    ])
    ./hardware-configuration.nix
    ./network.nix
    ./cert.nix
    ./stacks
    ./monitoring.nix
    ./blocky.nix
  ];

  # Use the GRUB 2 boot loader.
  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
    };
    # use predictable network interface names (eth0)
    kernelParams = ["net.ifnames=0"];
  };

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    secrets.cloudflare = {};
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  networking.hostName = "${hostname}"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    busybox
  ];

  system.stateVersion = "24.11"; # Did you read the comment?
}
