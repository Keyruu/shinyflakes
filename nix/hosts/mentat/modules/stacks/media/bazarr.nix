{ config, ... }:
let
  bazarrPath = "/etc/stacks/bazarr";
  my = config.services.my.bazarr;
in
{
  systemd.tmpfiles.rules = [
    "d ${bazarrPath}/config 0755 root root"
  ];

  services.my.bazarr = {
    port = 6767;
    domain = "bazarr.lab.keyruu.de";
  };

  virtualisation.quadlet.containers = {
    media-bazarr = {
      containerConfig = {
        image = "ghcr.io/hotio/bazarr:release-1.5.3";
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

  services.nginx.virtualHosts = {
    "${my.domain}" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString my.port}";
        proxyWebsockets = true;
      };
    };
  };

}
