{...}: 
  let
    sonarrPath = "/etc/stacks/sonarr";
  in {
  systemd.tmpfiles.rules = [
    "d ${sonarrPath}/config 0755 root root"
  ];

  virtualisation.quadlet.containers.torrent-sonarr = {
    containerConfig = {
      image = "ghcr.io/hotio/sonarr:release";
      environments = {
        PUID = "0";
        PGID = "0";
        UMASK = "022";
        TZ = "Europe/Berlin";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${sonarrPath}/config:/config"
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
