{lib, modules, pkgs, hostname, ...}: {
  imports = lib.flatten [
    (with modules; [
      locale
      ssh-access
      nginx
      podman
      beszel-agent
    ])
    ./disk-config.nix
    ./hardware-configuration.nix
    ./network.nix
    ./nginx.nix
    ./cert.nix
    ./cockpit.nix
    ./nas.nix
    ./monitoring
    ./stacks
    ./homepage.nix
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
      headscaleAuthKey.owner = "root";
      immichEnv.owner = "root";
      gluetunEnv.owner = "root";
    };
  };

  networking.hostName = "${hostname}"; # Define your hostname.

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    busybox
    ethtool
    podman-tui
    smartmontools
    pv
    tmux
    slirp4netns
    amdgpu_top
    lazydocker
    usbutils
    beets
  ];

  system.stateVersion = "24.11"; # Did you read the comment?
}
