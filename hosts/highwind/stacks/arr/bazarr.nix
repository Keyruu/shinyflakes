{...}: let
    bazarrPath = "/etc/stacks/bazarr";
  in {
  systemd.tmpfiles.rules = [
    "d ${bazarrPath}/config 0755 root root"
  ];

  virtualisation.quadlet.containers.torrent-bazarr = {
    containerConfig = {
      image = "ghcr.io/hotio/bazarr:release";
      environments = {
        PUID = "0";
        PGID = "0";
        UMASK = "022";
        TZ = "Europe/Berlin";
        WEBUI_PORTS = "6767/tcp,6767/udp";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${bazarrPath}/config:/config"
        "/main/media:/data"
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
