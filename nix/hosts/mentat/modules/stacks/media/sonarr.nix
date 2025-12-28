_:
let
  sonarrPath = "/etc/stacks/sonarr";
in
{
  systemd.tmpfiles.rules = [
    "d ${sonarrPath}/config 0755 root root"
  ];

  virtualisation.quadlet.containers = {
    media-sonarr = {
      containerConfig = {
        image = "ghcr.io/hotio/sonarr:release-4.0.16.2944";
        environments = {
          PUID = "0";
          PGID = "0";
          UMASK = "022";
          TZ = "Europe/Berlin";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${sonarrPath}/config:/config"
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
      "127.0.0.1:8989:8989"
    ];
  };

  services.nginx.virtualHosts = {
    "sonarr.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8989";
        proxyWebsockets = true;
      };
    };
  };
}
