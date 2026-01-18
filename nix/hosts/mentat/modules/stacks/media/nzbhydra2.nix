{ config, pkgs, ... }:
let
  stackPath = "/etc/stacks/nzbhydra2";
  my = config.services.my.nzbhydra2;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
  ];

  services.my.nzbhydra2 = {
    port = 5076;
    domain = "nzbhydra2.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit = "media-nzbhydra2";
    };
  };

  virtualisation.quadlet.containers = {
    media-nzbhydra2 = {
      containerConfig = {
        image = "lscr.io/linuxserver/nzbhydra2:8.3.0";
        environments = {
          PUID = "0";
          PGID = "0";
          TZ = "Europe/Berlin";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${stackPath}/config:/config"
          "/main/media/downloads:/data/downloads"
        ];
        networks = [
          "media-gluetun.container"
        ];
      };
      serviceConfig = {
        Restart = "always";
      };
      unitConfig = {
        After = [ "media-gluetun.service" ];
        Requires = [ "media-gluetun.service" ];
      };
    };
    media-gluetun.containerConfig.publishPorts = [
      "127.0.0.1:${toString my.port}:5076"
    ];
  };
}
