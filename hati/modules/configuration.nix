{ config, lib, pkgs, hostname, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./disk-config.nix
      ./hardware-configuration.nix
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
  ];

  system.stateVersion = "24.11"; # Did you read the comment?
}
