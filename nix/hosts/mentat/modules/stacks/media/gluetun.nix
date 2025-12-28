{ config, ... }:
{
  virtualisation.quadlet.containers.media-gluetun = {
    containerConfig = {
      image = "ghcr.io/qdm12/gluetun:v3.41.0";
      addCapabilities = [ "NET_ADMIN" ];
      devices = [ "/dev/net/tun:/dev/net/tun" ];
      environments = {
        FIREWALL_VPN_INPUT_PORTS = "53622,15403";
      };
      environmentFiles = [ config.sops.secrets.gluetunEnv.path ];
      labels = [
        "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
