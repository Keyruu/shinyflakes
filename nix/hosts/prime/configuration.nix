{
  config,
  inputs,
  flake,
  pkgs,
  ...
}:
let
  inherit (config.services) mesh;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.quadlet-nix.nixosModules.quadlet

    flake.modules.nixos.hetzner
    flake.modules.nixos.core
    flake.modules.nixos.server
    flake.modules.nixos.locale
    # flake.modules.nixos.nginx
    flake.modules.nixos.podman
    flake.modules.nixos.beszel-agent
    flake.modules.nixos.caddy

    flake.modules.services.monitoring
    ./modules
  ];

  sops = {
    secrets = {
      cloudflare = { };
      resticServerPassword = { };
    };
    templates."resticRepo".content =
      "rest:http://lucas:${config.sops.placeholder.resticServerPassword}@${mesh.people.lucas.devices.mentat.ip}:8004/restic";
  };

  networking.hosts."100.67.0.2" = [
    "cache.keyruu.de"
    "git.lab.keyruu.de"
  ];
  services = {
    mesh.server.enable = true;
    monitoring = {
      metrics = {
        enable = true;
        inherit (mesh) interface;
      };
      logs = {
        enable = true;
        instance = "100.67.0.1";
        lokiAddress = "http://${mesh.people.lucas.devices.mentat.ip}:3030";
      };
    };
    restic.defaultRepoFile = config.sops.templates."resticRepo".path;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    busybox
    ethtool
    dsnet
    kanidm_1_8
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.05";
}
