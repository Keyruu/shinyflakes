{
  config,
  inputs,
  flake,
  pkgs,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.quadlet-nix.nixosModules.quadlet

    flake.modules.nixos.core
    flake.modules.nixos.server
    flake.modules.nixos.locale
    flake.modules.nixos.nginx
    flake.modules.nixos.podman
    flake.modules.nixos.beszel-agent
    flake.modules.nixos.syncthing

    # Import local modules and services
    ./hardware-configuration.nix
    ./modules
  ];

  user.name = "root";

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
    kernelParams = [ "net.ifnames=0" ];
  };

  # boot.kernelPackages = pkgs.linuxPackages_6_16;

  services.resolved.enable = false;

  hardware.cpu.amd.ryzen-smu.enable = true;

  users.groups.smtp.members = [ "root" ];

  sops = {
    secrets = {
      cloudflare.owner = "root";
      resendApiKey = {
        owner = "root";
        group = "smtp";
        mode = "0440";
      };
      headscaleAuthKey.owner = "root";
      immichEnv.owner = "root";
      gluetunEnv.owner = "root";
      lidarrKey.owner = "root";
      sonarrKey.owner = "root";
      radarrKey.owner = "root";
      bazarrKey.owner = "root";
      prowlarrKey.owner = "root";
      qbittorrentUsername.owner = "root";
      qbittorrentPassword.owner = "root";
      beszelUsername.owner = "root";
      beszelPassword.owner = "root";
      jellyfinKey.owner = "root";
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    busybox
    ethtool
    podman-tui
    smartmontools
    pv
    tmux
    slirp4netns
    lazydocker
    usbutils
    beets
    conmon
    runc
    powertop
    ryzen-monitor-ng
    isd
    nvtopPackages.nvidia
  ];

  system.stateVersion = "24.11";
}
