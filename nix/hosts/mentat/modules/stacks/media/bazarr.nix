_:
let
  bazarrPath = "/etc/stacks/bazarr";
in
{
  systemd.tmpfiles.rules = [
    "d ${bazarrPath}/config 0755 root root"
  ];

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
      "127.0.0.1:6767:6767"
    ];
  };
}
