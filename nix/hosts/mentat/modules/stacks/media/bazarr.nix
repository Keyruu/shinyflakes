{ config, pkgs, ... }:
let
  stackPath = "/etc/stacks/bazarr";
  my = config.services.my.bazarr;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
  ];

  services.my.bazarr = {
    port = 6767;
    domain = "bazarr.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit = "media-bazarr";
    };
  };

  virtualisation.quadlet.containers = {
    media-bazarr = {
      containerConfig = {
        image = "ghcr.io/hotio/bazarr:release-1.5.5";
        environments = {
          PUID = "0";
          PGID = "0";
          UMASK = "022";
          TZ = "Europe/Berlin";
          WEBUI_PORTS = "6767/tcp,6767/udp";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${stackPath}/config:/config"
          "/main/media:/data"
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
      "127.0.0.1:${toString my.port}:6767"
    ];
  };
}
