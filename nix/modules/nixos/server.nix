{ flake, ... }:
{
  imports = [
    flake.modules.nixos.headless
    flake.modules.nixos.ssh-access
  ];
}