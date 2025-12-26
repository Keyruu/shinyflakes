{ ... }:
{
  imports = [
    ./sonarr.nix
    ./gluetun.nix
    ./radarr.nix
    ./bazarr.nix
    ./prowlarr.nix
    # ./qbittorrent.nix
    ./flaresolverr.nix
    ./jellyfin.nix
    ./navidrome.nix
    ./recyclarr.nix
    ./lidarr.nix
    ./sabnzbd.nix
    ./nzbhydra2.nix
  ];
}
