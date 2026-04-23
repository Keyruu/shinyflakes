{ config, ... }:
let
  my = config.services.my.esphome;
in
{
  services.my.esphome = {
    port = 6052;
    domain = "esphome.port.peeraten.net";
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "config" ];
      security.enable = false;
      containers.esphome = {
        containerConfig = {
          image = "ghcr.io/esphome/esphome:2026.4.2";
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
            "${my.stack.path}/config:/config"
          ];
          networks = [
            "host"
          ];
        };
      };
    };
  };
}
