_:
let
  stackName = "pigallery2";
  stackPath = "/etc/stacks/${stackName}";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
    "d ${stackPath}/tmp 0755 root root"
    "d ${stackPath}/db 0755 root root"
  ];

  virtualisation.quadlet = {
    containers = {
      "${stackName}" = {
        containerConfig = {
          image = "docker.io/bpatrik/pigallery2:latest";
          publishPorts = [ "127.0.0.1:8091:80" ];
          volumes = [
            "${stackPath}/config:/app/data/config"
            "${stackPath}/db:/app/data/db"
            "${stackPath}/tmp:/app/data/tmp"
            "/main:/app/data/images:ro"
          ];
          environments = {
            NODE_ENV = "production";
          };
          labels = [
            "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
          ];
        };
        serviceConfig = {
          Restart = "unless-stopped";
        };
      };
    };
  };

  services.nginx.virtualHosts."gallery.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8091";
      proxyWebsockets = true;
    };
  };
}
