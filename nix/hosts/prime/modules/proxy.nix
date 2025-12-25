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
    "s3.keyruu.de" = {
      proxyHost = "100.64.0.1";
      proxyPort = 3900;
    };
    "garage.keyruu.de" = {
      proxyHost = "100.64.0.1";
      proxyPort = 3902;
    };
    "29112025karaoke.keyruu.de" = {
      proxyHost = "100.64.0.1";
      proxyPort = 5555;
    };
    "atuin.keyruu.de" = {
      proxyHost = "100.64.0.1";
      proxyPort = 8888;
    };
    # "immich.keyruu.de" = { proxyHost = "100.64.0.1"; proxyPort = 3210; };
    # "*.zimtix.de" = { proxyHost = "192.168.100.32"; proxyPort = 80; };
  };

  mkProxyHost =
    { proxyHost, proxyPort }:
    {
      extraConfig = ''
        reverse_proxy http://${proxyHost}:${toString proxyPort}
      '';
    };
in
{
  services.caddy.virtualHostsWithDefaults = lib.mapAttrs (_: mkProxyHost) proxyHosts;
}
