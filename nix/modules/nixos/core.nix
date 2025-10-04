{ flake, ... }:
{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.hardening
    flake.modules.nixos.gc
  ];
}