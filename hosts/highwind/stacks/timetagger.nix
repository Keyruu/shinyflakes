{ config, ... }:
let
  stackPath = "/etc/stacks/timetagger";
in
{
  # Directory creation
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  # Quadlet configuration
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.timetagger.networkConfig.driver = "bridge";
      
      containers = {
        timetagger = {
          containerConfig = {
            image = "ghcr.io/almarklein/timetagger";
            publishPorts = [ "127.0.0.1:8080:80" ];
            volumes = [ "${stackPath}/data:/root/_timetagger" ];
            environments = {
              TIMETAGGER_BIND = "0.0.0.0:80";
              TIMETAGGER_DATADIR = "/root/_timetagger";
              TIMETAGGER_LOG_LEVEL = "info";
              TIMETAGGER_CREDENTIALS = "test:$$2a$$08$$0CD1NFiIbancwWsu3se1v.RNR/b7YeZd71yg3cZ/3whGlyU6Iny5i";
            };
            networks = [ networks.timetagger.ref ];
          };
          serviceConfig = {
            Restart = "unless-stopped";
          };
        };
      };
    };

  # Nginx reverse proxy
  services.nginx.virtualHosts."timetagger.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      proxyWebsockets = true;
    };
  };
}