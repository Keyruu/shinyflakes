{...}: let
    radarrPath = "/etc/stacks/radarr";
  in {
  systemd.tmpfiles.rules = [
    "d ${radarrPath}/config 0755 root root"
  ];

  virtualisation.quadlet.containers.torrent-radarr = {
    containerConfig = {
      image = "ghcr.io/hotio/radarr:release";
      environments = {
        PUID = "0";
        PGID = "0";
        UMASK = "022";
        TZ = "Europe/Berlin";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${radarrPath}/config:/config"
        "/main/media:/data"
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
