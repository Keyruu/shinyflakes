{ flake, hostName, ... }:
{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.hardening
    flake.modules.nixos.gc
  ];

  networking.hostName = hostName;
}
