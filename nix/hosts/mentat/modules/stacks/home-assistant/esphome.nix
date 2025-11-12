{ ... }:
let
  esphomePath = "/etc/stacks/esphome/config";
in
{
  systemd.tmpfiles.rules = [
    "d ${esphomePath} 0755 root root"
  ];

  virtualisation.quadlet.containers.esphome = {
    containerConfig = {
      image = "ghcr.io/esphome/esphome:2025.10.5";
      environments = {
        TZ = "Europe/Berlin";
      };
      exposePorts = [
        "6052"
      ];
      addCapabilities = [
        "CAP_NET_RAW"
      ];
      volumes = [
        "${esphomePath}:/config"
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

  services.nginx.virtualHosts."esphome.port.peeraten.net" = {
    useACMEHost = "port.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:6052";
      proxyWebsockets = true;
    };
  };
}
