{ ... }:
{
  den.aspects.services.media.gluetun = {
    nixos = { config, ... }: {
      sops.secrets.gluetunEnv = { };

      virtualisation.quadlet.containers.media-gluetun = {
        containerConfig = {
          image = "ghcr.io/qdm12/gluetun:v3.41.3";
          addCapabilities = [ "NET_ADMIN" ];
          devices = [ "/dev/net/tun:/dev/net/tun" ];
          environments = {
            FIREWALL_VPN_INPUT_PORTS = "53622,15403";
            # Disable IPv6: gluetun has no global v6 route, DNS still returns
            # AAAA records, apps try v6 first and time out → manifests as
            # indexer BadGateway / sonarr "doctype" errors when NZBs come back
            # as connection-error HTML.
            IPV6 = "false";
          };
          environmentFiles = [ config.sops.secrets.gluetunEnv.path ];
        };
      };
    };
  };
}
