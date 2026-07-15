{
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
    flake.modules.services.monitoring
    flake.modules.nixos.beszel-agent
    flake.modules.private.syncthing

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

  boot.kernelPackages = pkgs.linuxPackages_6_18;

  networking.nftables.enable = true;

  services.resolved.enable = false;
  # services.deploy-webhook = {
  #   enable = true;
  #   flake = "github:Keyruu/shinyflakes";
  #   interfaces = [ "eth0" ];
  # };

  services.monitoring = {
    metrics = {
      enable = true;
      interface = "eth0";
    };
    logs = {
      enable = true;
      instance = "127.0.0.1";
      lokiAddress = "http://127.0.0.1:3030";
    };
  };

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
    # beets
    conmon
    runc
    powertop
    ryzen-monitor-ng
    isd
    nvtopPackages.nvidia
    rustic
  ];

  system.stateVersion = "26.05";
}
