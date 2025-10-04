{
  flake,
  ...
}:
{
  imports = [
    flake.homeModules.mac
  ];

  home.stateVersion = "24.11";
}
