{
  lib,
  modules,
  ...
}:
{
  imports = lib.flatten [
    (with modules; [
      hetzner
      locale
      nginx
      ssh-access
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

  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  networking.hostName = "sleipnir";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
