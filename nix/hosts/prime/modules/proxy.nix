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
      cloudflare = true;
    };
    "owntracks.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 5144;
      cloudflare = true;
    };
    "map.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 3001;
      cloudflare = true;
    };
    "calendar.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 5232;
      cloudflare = true;
    };
    "files.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 3210;
      cloudflare = true;
    };
    "s3.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 3900;
      cloudflare = true;
    };
    "garage.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 3902;
      cloudflare = true;
    };
    "29112025karaoke.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 5555;
      cloudflare = false;
    };
    # "git.keyruu.de" = {
    #   proxyHost = mentat;
    #   proxyPort = 3004;
    # };
    # "immich.keyruu.de" = { proxyHost = "100.67.0.2"; proxyPort = 3210; };
    # "*.zimtix.de" = { proxyHost = "192.168.100.32"; proxyPort = 80; };
  };

  mkProxyHost =
    {
      proxyHost,
      proxyPort,
      cloudflare,
    }:
    {
      extraConfig = ''
        ${lib.optionalString cloudflare "import cloudflare-only"}
        reverse_proxy http://${proxyHost}:${toString proxyPort} 
      '';
    };
in
{
  services.caddy = {
    virtualHostsWithDefaults = (lib.mapAttrs (_: mkProxyHost) proxyHosts) // {
      "git.keyruu.de" = {
        extraConfig = ''
          import cloudflare-only
          reverse_proxy http://${mentat}:3004 {
          	header_up X-Real-Ip {remote_host}
          }
        '';
      };
    };
    virtualHosts = {
      # i need to split out the websocket, bc coraza just can't handle the upgrade or the websocket in general
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

                  # remove REQUEST-949-BLOCKING-EVALUATION bc of a lot of false positives
                  SecRuleRemoveById 949110
                  # somehow this blocks some http protocol, idfk 
                  SecRuleRemoveById 920420
                `
              }

              import cloudflare-only
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
