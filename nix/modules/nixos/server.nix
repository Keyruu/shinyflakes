{ flake, ... }:
{
  imports = [
    flake.modules.nixos.headless
    flake.modules.nixos.comin
    flake.modules.nixos.ssh-access
  ];

  user.name = "root";
}
