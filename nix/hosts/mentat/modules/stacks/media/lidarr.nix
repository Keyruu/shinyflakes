_:
let
  lidarrPath = "/etc/stacks/lidarr/config";
in
{
  systemd.tmpfiles.rules = [
    "d ${lidarrPath}/config 0755 root root"
  ];

  virtualisation.quadlet.containers = {
    media-lidarr = {
      containerConfig = {
        image = "ghcr.io/hotio/lidarr:release-3.1.0.4875";
        environments = {
          PUID = "0";
          PGID = "0";
          UMASK = "022";
          TZ = "Europe/Berlin";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${lidarrPath}/config:/config"
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
      "127.0.0.1:8686:8686"
    ];
  };
}
