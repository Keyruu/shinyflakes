{ config, ... }:
let
  slskdPath = "/etc/stacks/slskd/app";
  musicPath = "/main/media/Music";
in
{
  systemd.tmpfiles.rules = [
    "d ${slskdPath} 0755 root root"
    "d ${musicPath}/downloads/completed 0755 root root"
    "d ${musicPath}/downloads/incomplete 0755 root root"
    "d ${musicPath}/library 0755 root root"
  ];

  sops.secrets.slskdEnv.owner = "root";

  sops.secrets = {
    slskdKey.owner = "root";
    lidarrKey.owner = "root";
  };

  sops.templates."slskdConfig.yaml".content = # yaml
    ''
      web:
        authentication:
          api_keys:
            soularr_key:
              key: ${config.sops.placeholder.slskdKey}
    '';

  virtualisation.quadlet.containers.torrent-slskd = {
    containerConfig = {
      image = "slskd/slskd:0.22.2.0-a2e1e65b";
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
        "${config.sops.templates."slskdConfig.yaml".path}:/app/slskd.yml:ro"
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
