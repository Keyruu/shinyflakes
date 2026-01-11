{ flake, hostName, ... }:
{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.hardening
    flake.modules.nixos.gc
    flake.modules.services.mesh
  ];

  networking.hostName = hostName;
}
