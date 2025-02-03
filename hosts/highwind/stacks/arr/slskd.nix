{config, ...}: 
let
  slskdPath = "/etc/stacks/radarr/app";
  musicPath = "/main/media/Music";
in {
  systemd.tmpfiles.rules = [
    "d ${slskdPath} 0755 root root"
    "d ${musicPath}/downloads/completed 0755 root root"
    "d ${musicPath}/downloads/incomplete 0755 root root"
    "d ${musicPath}/library 0755 root root"
  ];

  sops.secrets.slskdEnv.owner = "root";

  virtualisation.quadlet.containers.torrent-slskd = {
    containerConfig = {
      image = "slskd/slskd:0.22.1.65534-a2e1e65b";
      environments = {
        SLSKD_UMASK = "022";
        SLSKD_DOWNLOADS_DIR = "/data/Music/downloads/completed";
        SLSKD_INCOMPLETE_DIR = "/data/Music/downloads/incomplete";
        SLSKD_SHARED_DIR = "/data/Music/library";
        SLSKD_SHARE_FILTER = "\.ini$;Thumbs.db$;\.DS_Store$";
        TZ = "Europe/Berlin";
      };
      environmentFiles = [
        config.sops.secrets.slskdEnv.path
      ];
      volumes = [
        "${slskdPath}:/app"
        "/main/media/Music:/data/Music"
      ];
      networks = [
        "torrent--gluetun.container"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
    unitConfig = {
      After = [ "torrent--gluetun.service" ];
      Requires = [ "torrent--gluetun.service" ];
    };
  };
}

