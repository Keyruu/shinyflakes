{ config, ... }:
let
  musicAssistantPath = "/etc/stacks/music-assistant";
  my = config.services.my.music-assistant;
in
{
  systemd.tmpfiles.rules = [
    "d ${musicAssistantPath}/data 0755 root root"
  ];

  networking.firewall.interfaces.eth0.allowedTCPPorts = [ 8097 ];

  services.my.music-assistant = {
    port = 8095;
    domain = "music.port.peeraten.net";
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
  };

  virtualisation.quadlet.containers.music-assistant = {
    containerConfig = {
      image = "ghcr.io/music-assistant/server:2.7.3";
      environments = {
        TZ = "Europe/Berlin";
      };
      exposePorts = [
        "8095"
      ];
      volumes = [
        "${musicAssistantPath}/data:/data"
      ];
      networks = [
        "host"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
