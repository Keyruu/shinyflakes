{ lib, config, ... }:
let
  mentat = config.services.mesh.people.lucas.devices.mentat.ip;
  proxyHosts = {
    # "hass.peeraten.net" = {
    #   proxyHost = mentat;
    #   proxyPort = 8123;
    # };
    "traccar.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 5785;
    };
    "owntracks.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 5144;
    };
    "map.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 3001;
    };
    "calendar.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 5232;
    };
    "files.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 3210;
    };
    "s3.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 3900;
    };
    "garage.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 3902;
    };
    "29112025karaoke.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 5555;
    };
    "atuin.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 8888;
    };
    # "immich.keyruu.de" = { proxyHost = "100.67.0.2"; proxyPort = 3210; };
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
  services.caddy.virtualHostsWithDefaults = lib.mkMerge [
    (lib.mapAttrs (_: mkProxyHost) proxyHosts)
    {
      "hass.peeraten.net" = {
        extraConfig = ''
          reverse_proxy http://${mentat}:8123 {
            header_up X-Real-IP {http.request.header.CF-Connecting-IP}
            header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
          }
        '';
      };
    }
  ];
}
