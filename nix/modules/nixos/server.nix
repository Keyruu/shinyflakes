{ flake, ... }:
{
  imports = [
    flake.modules.nixos.headless
    flake.modules.nixos.auto-upgrade
    flake.modules.nixos.ssh-access
  ];

  user.name = "root";
}
