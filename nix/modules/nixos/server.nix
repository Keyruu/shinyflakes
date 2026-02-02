{ flake, pkgs, ... }:
{
  imports = [
    flake.modules.nixos.headless
    # flake.modules.nixos.auto-upgrade
    flake.modules.nixos.comin
    flake.modules.nixos.ssh-access
    flake.modules.nixos.podman
    flake.modules.nixos.quadlet
    # flake.modules.services.deploy

    flake.modules.services.backup
    flake.modules.services.my
  ];

  user.name = "root";

  environment.systemPackages = with pkgs; [
    isd
  ];

  networking.firewall.allowPing = true;
}
