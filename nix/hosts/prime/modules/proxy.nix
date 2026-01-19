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
  services.caddy = {
    virtualHostsWithDefaults = lib.mkMerge [
      (lib.mapAttrs (_: mkProxyHost) proxyHosts)
      # {
      #   "hass.peeraten.net" = {
      #     extraConfig = ''
      #       log {
      #         output stdout
      #         level DEBUG
      #       }
      #
      #       reverse_proxy http://${mentat}:8123 {
      #         header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
      #       }
      #     '';
      #   };
      # }
    ];
    virtualHosts = {
      "hass.peeraten.net" = {
        extraConfig = ''
          @websockets {
            path /api/websocket
          }
          handle @websockets {
            reverse_proxy ${mentat}:8123 {
              header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
            }
          }
          handle {
            route {
              coraza_waf {
                load_owasp_crs
                directives `
                  SecRuleEngine On
                  Include @coraza.conf-recommended
                  Include @crs-setup.conf.example
                  Include @owasp_crs/*.conf

                  # remove REQUEST-949-BLOCKING-EVALUATION, REQUEST-932-APPLICATION-ATTACK-RCE.conf, REQUEST-911-METHOD-ENFORCEMENT.conf bc of a lot of false positives
                  SecRuleRemoveById 949110
                  # somehow this blocks some http protocol, idfk 
                  SecRuleRemoveById 920420
          `
              }

              reverse_proxy http://${mentat}:8123 {
                header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
              }
            }
          }
        '';
      };
    };
  };
}
