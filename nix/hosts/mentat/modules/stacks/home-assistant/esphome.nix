{ config, ... }:
let
  esphomePath = "/etc/stacks/esphome/config";
  my = config.services.my.esphome;
in
{
  systemd.tmpfiles.rules = [
    "d ${esphomePath} 0755 root root"
  ];

  services.my.esphome = {
    port = 6052;
    domain = "esphome.port.peeraten.net";
  };

  virtualisation.quadlet.containers.esphome = {
    containerConfig = {
      image = "ghcr.io/esphome/esphome:2025.12.6";
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

  services.nginx.virtualHosts."${my.domain}" = {
    useACMEHost = "port.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString my.port}";
      proxyWebsockets = true;
    };
  };
}
