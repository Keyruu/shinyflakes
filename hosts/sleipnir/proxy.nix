{ config, ... }:
{
  services.nginx.virtualHosts."hass.peeraten.net" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://100.64.0.1:8123";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."traccar.peeraten.net" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://100.64.0.1:5785";
      proxyWebsockets = true;
    };
  };

  # services.nginx.virtualHosts."immich.keyruu.de" = {
  #   enableACME = true;
  #   forceSSL = true;
  #
  #   locations."/" = {
  #     proxyPass = "http://hati:2283";
  #     proxyWebsockets = true;
  #   };
  # };

  # services.nginx.virtualHosts."*.zimtix.de" = {
  #   locations."/" = {
  #     proxyPass = "http://192.168.100.32:80";
  #     proxyWebsockets = true;
  #   };
  # };
}
