{ config, ... }:
let
  nzbhydra2 = "/etc/stacks/nzbhydra2";
  my = config.services.my.nzbhydra2;
in
{
  systemd.tmpfiles.rules = [
    "d ${nzbhydra2}/config 0755 root root"
  ];

  services.my.nzbhydra2 = {
    port = 5076;
    domain = "nzbhydra2.lab.keyruu.de";
    proxy.enable = true;
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
          "${nzbhydra2}/config:/config"
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
