{ flake, ... }:
{
  # Common home-manager configuration
  imports = [
    flake.modules.home.common.common
  ];
}