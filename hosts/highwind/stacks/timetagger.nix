{ config, ... }:
let
  stackPath = "/etc/stacks/timetagger";
in
{
  # Sops secrets
  sops.secrets = {
    timetaggerCreds = { };
  };

  # Directory creation
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  # Environment template
  sops.templates."timetagger.env".content = ''
    TIMETAGGER_CREDENTIALS=${config.sops.placeholder.timetaggerCreds}
  '';

  # Quadlet configuration
  virtualisation.quadlet = {
    containers = {
      timetagger = {
        containerConfig = {
          image = "ghcr.io/almarklein/timetagger";
          publishPorts = [ "127.0.0.1:8085:80" ];
          volumes = [ "${stackPath}/data:/root/_timetagger" ];
          environments = {
            TIMETAGGER_BIND = "0.0.0.0:80";
            TIMETAGGER_DATADIR = "/root/_timetagger";
            TIMETAGGER_LOG_LEVEL = "info";
          };
          environmentFiles = [ config.sops.templates."timetagger.env".path ];
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
      proxyPass = "http://127.0.0.1:8085";
      proxyWebsockets = true;
    };
  };
}
