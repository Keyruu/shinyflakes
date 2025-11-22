{ flake, pkgs, ... }:
{
  imports = [
    flake.modules.nixos.headless
    flake.modules.nixos.auto-upgrade
    flake.modules.nixos.ssh-access
  ];

  user.name = "root";

  environment.systemPackages = with pkgs; [
    isd
  ];
}
