{ pkgs, ... }:
{
  imports = [
    ./extensions
  ];

  home.packages = with pkgs; [
    pi-coding-agent
  ];
}
