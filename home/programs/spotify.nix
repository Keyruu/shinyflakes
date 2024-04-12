{ pkgs, ... }: {
  services.spotifyd.enable = true;

  home.packages = with pkgs; [
    spotify-player
    spotify-qt
  ];
}
