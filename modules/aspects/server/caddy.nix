{ den, ... }:
{
  den.aspects.server.caddy = {
    includes = [ den.aspects.options.cloudflare ];

    nixos =
      {
        config,
        self',
        lib,
        ...
      }:
      {
        sops = {
          secrets = {
            caddyPasswordHash = { };
          };
          templates."caddy.env" = {
            owner = "caddy";
            group = "caddy";
            content = ''
              PASSWORD_HASH=${config.sops.placeholder.caddyPasswordHash}
            '';
          };
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        security.acme = {
          acceptTerms = true;
          defaults.email = "me@keyruu.de";
        };

        services.logrotate.settings.caddy = {
          files = "/var/log/caddy/*.log";
          frequency = "daily";
          rotate = 3;
          maxsize = "50M";
          compress = true;
          copytruncate = true;
          su = "caddy caddy";
        };

        services.caddy = {
          enable = true;
          package = self'.packages.caddy;
          environmentFile = config.sops.templates."caddy.env".path;

          logDir = "/var/log/caddy";

          globalConfig = ''
            order coraza_waf first
            servers {
              trusted_proxies static ${lib.concatStringsSep " " config.cloudflare.ips.all}
              trusted_proxies_strict
              client_ip_headers Cf-Connecting-Ip X-Forwarded-For
            }
          '';

          extraConfig = ''
            (cloudflare-only) {
              @not-cloudflare {
                not remote_ip ${lib.concatStringsSep " " config.cloudflare.ips.all}
              }
              respond @not-cloudflare 403
            }

            (coraza-waf) {
              coraza_waf {
                load_owasp_crs
                directives `
                  SecRuleEngine On

                  Include @coraza.conf-recommended
                  Include @crs-setup.conf.example
                  Include @owasp_crs/*.conf

                  SecRuleRemoveById 949110
                  SecRuleRemoveById 932370
                  SecRuleRemoveById 911100
                  SecRuleRemoveById 920420
                  SecRuleRemoveById 200002
                  SecRuleRemoveById 200003
                `
              }
            }

            (websocket) {
              handle {args[0]} {
                @websockets {
                  header_regexp Connection Upgrade
                  header        Upgrade websocket
                }
                reverse_proxy @websockets {args[1]}
              }
            }
          '';
        };
      };
  };
}
