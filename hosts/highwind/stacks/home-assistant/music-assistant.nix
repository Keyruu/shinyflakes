{config, ...}: let
  musicAssistantPath = "/etc/stacks/music-assistant";
in {
  systemd.tmpfiles.rules = [
    "d ${musicAssistantPath}/data 0755 root root"
  ];

  networking.firewall.allowedTCPPorts = [ 8097 ];

  virtualisation.quadlet.containers.music-assistant = {
    containerConfig = {
      image = "ghcr.io/music-assistant/server:2.5.2";
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
      labels = [
        "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };


  services.nginx.virtualHosts."music.port.peeraten.net" = {
    useACMEHost = "port.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8095";
      proxyWebsockets = true;
    };
  };
}

