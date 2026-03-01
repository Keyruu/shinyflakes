{ config, flake, ... }:
let
  stackPath = "/etc/stacks/sabnzbd";
  my = config.services.my.sabnzbd;
  inherit (config.virtualisation.quadlet) containers;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
  ];

  services.my.sabnzbd = {
    port = 8022;
    domain = "sabnzbd.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit = "media-sabnzbd";
    };
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
        After = [ containers.media-gluetun.ref ];
        Requires = [ containers.media-gluetun.ref ];
      };
    };
    media-gluetun.containerConfig.publishPorts = [
      "${toString my.port}:8085"
    ];
  };
}
