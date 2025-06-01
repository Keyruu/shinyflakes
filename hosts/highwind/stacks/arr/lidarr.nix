{ ... }:
let
  lidarrPath = "/etc/stacks/lidarr/config";
in
{
  systemd.tmpfiles.rules = [
    "d ${lidarrPath}/config 0755 root root"
  ];

  virtualisation.quadlet.containers.torrent-lidarr = {
    containerConfig = {
      image = "ghcr.io/hotio/lidarr:release";
      environments = {
        PUID = "0";
        PGID = "0";
        UMASK = "022";
        TZ = "Europe/Berlin";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${lidarrPath}/config:/config"
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
