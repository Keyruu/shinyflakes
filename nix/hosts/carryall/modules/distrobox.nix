{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    distrobox
  ];

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
}
