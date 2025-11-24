{ flake, hostName, ... }:
{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.hardening
    flake.modules.nixos.gc
    flake.modules.nixos.cache
  ];

  networking.hostName = hostName;
}
