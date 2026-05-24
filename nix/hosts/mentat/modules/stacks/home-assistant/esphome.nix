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
      directories = [ "config" "platformio" ];
      security.enable = false;
      containers.esphome = {
        containerConfig = {
          image = "ghcr.io/esphome/esphome:2026.5.1";
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
            "${my.stack.path}/platformio:/root/.platformio"
          ];
          networks = [
            "host"
          ];
        };
      };
    };
  };
}
