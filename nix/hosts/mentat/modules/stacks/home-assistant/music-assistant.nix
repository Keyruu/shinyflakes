{ config, ... }:
let
  my = config.services.my.music-assistant;
in
{
  networking.firewall.interfaces.eth0.allowedTCPPorts = [
    8095
    8097
  ];

  services.my.music-assistant = {
    port = 8095;
    domain = "music.port.peeraten.net";
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = false;
      containers.music-assistant = {
        containerConfig = {
          image = "ghcr.io/music-assistant/server:2.8.2";
          environments = {
            TZ = "Europe/Berlin";
          };
          exposePorts = [
            "8095"
          ];
          volumes = [
            "${my.stack.path}/data:/data"
          ];
          networks = [
            "host"
          ];
        };
      };
    };
  };
}
