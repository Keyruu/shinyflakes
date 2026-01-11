{ config, ... }:
let
  musicAssistantPath = "/etc/stacks/music-assistant";
  my = config.services.my.music-assistant;
in
{
  systemd.tmpfiles.rules = [
    "d ${musicAssistantPath}/data 0755 root root"
  ];

  networking.firewall.allowedTCPPorts = [ 8097 ];

  services.my.music-assistant = {
    port = 8097;
    domain = "music.port.peeraten.net";
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

  services.nginx.virtualHosts."${my.domain}" = {
    useACMEHost = "port.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString my.port}";
      proxyWebsockets = true;
    };
  };
}
