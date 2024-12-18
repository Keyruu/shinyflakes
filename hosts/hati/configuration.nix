{
  modules,
  pkgs,
  hostname,
  sops,
  lib,
  ...
}: {
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
    ./monitoring
    ./nginx.nix
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

  users.groups.smtp.members = ["root"];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    secrets = {
      cloudflare.owner = "root";
      resendApiKey = {
        owner = "root";
        group = "smtp";
        mode = "0440";
      };
    };
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
    ethtool
  ];

  system.stateVersion = "24.11"; # Did you read the comment?
}
