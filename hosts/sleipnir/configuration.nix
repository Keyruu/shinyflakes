{
  lib,
  modules,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    (with modules; [
      hetzner
      locale
      nginx
      ssh-access
      podman
      beszel-agent
    ])
    ../../services/monitoring.nix
    ./headscale.nix
    ./proxy.nix
    ./nginx.nix
    ./kanidm.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    secrets = {
      cloudflare.owner = "root";
      headscaleOidc = {
        owner = "headscale";
        mode = "0440";
      };
      kanidmAdminPassword.owner = "kanidm";
      headplaneEnv.owner = "root";
      headscaleAuthKey.owner = "root";
    };
  };

  services.monitoring = {
    metrics = {
      enable = true;
      interface = "tailscale0";
    };
    logs = {
      enable = true;
      nginx = true;
      lokiAddress = "http://hati:3030";
    };
  };

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    busybox
    ethtool
  ];

  networking.hostName = "sleipnir";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
