{ flake, hostName, ... }:
{
  imports = [
    flake.modules.nixos.headless
    flake.modules.nixos.ssh-access
  ];

  user.name = "root";

  networking.hostName = hostName;
}
