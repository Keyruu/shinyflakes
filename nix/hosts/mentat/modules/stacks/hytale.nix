{ config, ... }:
let
  stackPath = "/etc/stacks/hytale";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 1000 1000"
  ];

  sops.secrets.hytaleServerPassword = { };
  sops.templates."hytale-server.env" = {
    restartUnits = [
      "hytale-server.service"
    ];
    content = ''
      HYTALE_SERVER_NAME=Der Server
      HYTALE_MOTD=Was geht ab, ihr Oberloser?
      HYTALE_PASSWORD=
      HYTALE_MAX_PLAYERS=1000
      HYTALE_MAX_VIEW_RADIUS=32
      HYTALE_COMPRESSION=false
      HYTALE_WORLD=petershausen
      HYTALE_GAMEMODE=Adventure
      HYTALE_ALLOW_OP=TRUE
    '';
  };

  virtualisation.quadlet.containers.hytale-server = {
    containerConfig = {
      image = "docker.io/deinfreu/hytale-server:experimental-0.1.3";
      publishPorts = [ "5520:5520/udp" ];
      volumes = [
        "${stackPath}/data:/home/container"
        "/etc/machine-id:/etc/machine-id:ro"
      ];
      environmentFiles = [ config.sops.templates."hytale-server.env".path ];
      environments = {
        SERVER_IP = "0.0.0.0";
        SERVER_PORT = "5520";
        PROD = "FALSE";
        DEBUG = "FALSE";
        TZ = "Europe/Amsterdam";
        CACHE = "TRUE";
      };
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
