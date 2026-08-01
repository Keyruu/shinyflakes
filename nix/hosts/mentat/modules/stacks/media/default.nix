{ ... }:
{
  imports = [
    ./sonarr.nix
    ./gluetun.nix
    ./radarr.nix
    ./bazarr.nix
    ./jellyfin.nix
    ./navidrome.nix
    ./recyclarr.nix
    ./lidarr.nix
    ./sabnzbd.nix
    ./prowlarr.nix
    ./seerr.nix
    # FIXME: beets broken on unstable
    # ./beets.nix
    ./tidaloader.nix
    ./nzbdav.nix
    ./nzbdav-rclone.nix
  ];
}
