{ den, ... }:
{
  den.aspects.services.media = {
    includes = [
      # VPN container — every media service joins its network
      den.aspects.services.media.gluetun
      # *arr stack + media servers
      den.aspects.services.media.sonarr
      den.aspects.services.media.radarr
      den.aspects.services.media.bazarr
      den.aspects.services.media.lidarr
      den.aspects.services.media.prowlarr
      den.aspects.services.media.sabnzbd
      den.aspects.services.media.recyclarr
      # Media servers
      den.aspects.services.media.jellyfin
      den.aspects.services.media.navidrome
      # Request management
      den.aspects.services.media.seerr
      # Misc
      den.aspects.services.media.tidaloader
    ];
  };
}
