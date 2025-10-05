{ pkgs, ... }:
{
  home.packages = with pkgs; [
    spotify-qt
    spotify-player
    librespot
    spotify
  ];
}
