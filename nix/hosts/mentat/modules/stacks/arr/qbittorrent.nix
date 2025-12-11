_:
let
  qbittorrentPath = "/etc/stacks/qbittorrent";
in
{
  systemd.tmpfiles.rules = [
    "d ${qbittorrentPath}/config 0770 root root"
  ];

  virtualisation.quadlet.containers.torrent-qbittorrent = {
    containerConfig = {
      image = "ghcr.io/hotio/qbittorrent:release";
      environments = {
        PUID = "0";
        PGID = "0";
        UMASK = "007";
        TZ = "Europe/Berlin";
        WEBUI_PORTS = "8080/tcp,8080/udp";
      };
      volumes = [
        "${qbittorrentPath}/config:/config"
        "/main/media/downloads:/data/downloads"
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
