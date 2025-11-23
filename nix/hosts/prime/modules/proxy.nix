{ lib, ... }:
let
  proxyHosts = {
    "hass.peeraten.net" = {
      proxyHost = "100.64.0.1";
      proxyPort = 8123;
    };
    "traccar.peeraten.net" = {
      proxyHost = "100.64.0.1";
      proxyPort = 5785;
    };
    "owntracks.peeraten.net" = {
      proxyHost = "100.64.0.1";
      proxyPort = 5144;
    };
    "map.peeraten.net" = {
      proxyHost = "100.64.0.1";
      proxyPort = 3001;
    };
    "calendar.peeraten.net" = {
      proxyHost = "100.64.0.1";
      proxyPort = 5232;
    };
    "files.keyruu.de" = {
      proxyHost = "100.64.0.1";
      proxyPort = 3210;
    };
    "n8n.keyruu.de" = {
      proxyHost = "100.64.0.1";
      proxyPort = 5678;
    };
    # "immich.keyruu.de" = { proxyHost = "100.64.0.1"; proxyPort = 3210; };
    # "*.zimtix.de" = { proxyHost = "192.168.100.32"; proxyPort = 80; };
  };

  mkProxyHost =
    { proxyHost, proxyPort }:
    {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${proxyHost}:${toString proxyPort}";
        proxyWebsockets = true;
        extraConfig = ''
          modsecurity on;
          modsecurity_rules_file /etc/nginx/modsec/main.conf;
        '';
      };
    };
in
{
  services.nginx.virtualHosts = lib.mapAttrs (_: mkProxyHost) proxyHosts;
}
