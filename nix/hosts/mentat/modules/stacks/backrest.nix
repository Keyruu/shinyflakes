{ config, ... }:
let
  stackPath = "/etc/stacks/dawarich";
  my = config.services.my.backrest;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/config 0755 root root"
    "d ${stackPath}/cache 0755 root root"
    "d ${stackPath}/tmp 0755 root root"
  ];

  services.my.backrest = {
    port = 9898;
    domain = "backrest.lab.keyruu.de";
    proxy.enable = true;
  };

  virtualisation.quadlet.containers.backrest = {
    containerConfig = {
      image = "ghcr.io/garethgeorge/backrest:v1.11.1";
      publishPorts = [ "127.0.0.1:${toString my.port}:9898" ];
      environments = {
        BACKREST_DATA = "/data";
        BACKREST_CONFIG = "/config/config.json";
        XDG_CACHE_HOME = "/cache";
        TMPDIR = "/tmp";
        TZ = "Europe/Amsterdam";
      };
      volumes = [
        "${stackPath}/data:/data"
        "${stackPath}/config:/config"
        "${stackPath}/cache:/cache"
        "${stackPath}/tmp:/tmp"
        "${config.services.restic.defaultRepo}:${config.services.restic.defaultRepo}"
      ];
    };
  };
}
