{ flake, pkgs, ... }:
{
  imports = [
    flake.modules.nixos.headless
    # flake.modules.nixos.auto-upgrade
    flake.modules.nixos.ssh-access
    flake.modules.nixos.podman
    flake.modules.nixos.quadlet

    flake.modules.services.backup
    flake.modules.services.my
    flake.modules.services.deploy
  ];

  user.name = "root";

  environment.systemPackages = with pkgs; [
    isd
  ];

  networking.firewall.allowPing = true;
}
