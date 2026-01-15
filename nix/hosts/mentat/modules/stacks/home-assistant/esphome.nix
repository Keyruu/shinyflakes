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
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
  };

  virtualisation.quadlet.containers.esphome = {
    containerConfig = {
      image = "ghcr.io/esphome/esphome:2025.12.5";
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
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
