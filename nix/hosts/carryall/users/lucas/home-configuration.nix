{ flake, ... }:
{
  imports = [
    flake.homeModules.linux
  ];

  home.stateVersion = "24.11";
}
