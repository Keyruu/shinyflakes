{...}: let
    prowlarrPath = "/etc/stacks/prowlarr";
  in {
  systemd.tmpfiles.rules = [
    "d ${prowlarrPath}/config 0755 root root"
  ];

  virtualisation.quadlet.containers.torrent-prowlarr = {
    containerConfig = {
      image = "ghcr.io/hotio/prowlarr:release";
      environments = {
        PUID = "0";
        PGID = "0";
        UMASK = "022";
        TZ = "Europe/Berlin";
      };
      volumes = [
        "${prowlarrPath}/config:/config"
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
