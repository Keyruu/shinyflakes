{ config, ... }:
let
  soularrPath = "/etc/stacks/soularr/data";
in
{
  systemd.tmpfiles.rules = [
    "d ${soularrPath} 0755 root root"
  ];

  sops.secrets.slskdKey.owner = "root";

  sops.templates."soularrConfig.toml".content = # toml
    ''
      [Lidarr]
      api_key = ${config.sops.placeholder.lidarrKey}
      host_url = http://localhost:8686
      download_dir = /data/Music/downloads/completed

      [Slskd]
      api_key = ${config.sops.placeholder.slskdKey}
      host_url = http://localhost:5030
      download_dir = /data/Music/downloads/completed
      delete_searches = False
      stalled_timeout = 3600

      [Release Settings]
      use_most_common_tracknum = True
      allow_multi_disc = True
      accepted_countries = Europe,Japan,United Kingdom,United States,[Worldwide],Australia,Canada
      accepted_formats = CD,Digital Media,Vinyl

      [Search Settings]
      search_timeout = 5000
      maximum_peer_queue = 50
      minimum_peer_upload_speed = 0
      minimum_filename_match_ratio = 0.5
      allowed_filetypes = flac,mp3
      search_for_tracks = True
      album_prepend_artist = False
      track_prepend_artist = True
      search_type = incrementing_page
      number_of_albums_to_grab = 10
      remove_wanted_on_failure = False
      search_source = missing
    '';

  virtualisation.quadlet.containers.torrent-soularr = {
    containerConfig = {
      image = "mrusse08/soularr:latest";
      environments = {
        PUID = "0";
        PGID = "0";
        TZ = "Europe/Berlin";
        SCRIPT_INTERVAL = "300";
      };
      volumes = [
        "${soularrPath}:/data"
        "${config.sops.templates."soularrConfig.toml".path}:/data/config.ini"
        "/main/media/Music:/data/Music"
      ];
      networks = [
        "torrent-gluetun.container"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
    unitConfig = {
      After = [ "torrent-gluetun.service" ];
      Requires = [ "torrent-gluetun.service" ];
    };
  };
}
