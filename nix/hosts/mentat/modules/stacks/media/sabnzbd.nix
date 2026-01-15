{ config, ... }:
let
  sabnzbdPath = "/etc/stacks/sabnzbd";
  my = config.services.my.sabnzbd;
in
{
  systemd.tmpfiles.rules = [
    "d ${sabnzbdPath}/config 0755 root root"
  ];

  services.my.sabnzbd = {
    port = 8022;
    domain = "sabnzbd.lab.keyruu.de";
    proxy.enable = true;
  };

  virtualisation.quadlet.containers = {
    media-sabnzbd = {
      containerConfig = {
        image = "lscr.io/linuxserver/sabnzbd:4.5.5";
        environments = {
          PUID = "0";
          PGID = "0";
          TZ = "Europe/Berlin";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${sabnzbdPath}/config:/config"
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
      "${toString my.port}:8085"
    ];
  };
}
