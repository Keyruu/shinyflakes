{...}: {
  imports = [
    ./sonarr.nix
    ./gluetun.nix
    ./radarr.nix
    ./bazarr.nix
    ./prowlarr.nix
    ./qbittorrent.nix
    ./flaresolverr.nix
    ./jellyfin.nix
    ./slskd.nix
    ./navidrome.nix
    ./beets.nix
  ];
}
