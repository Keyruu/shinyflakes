{ __findFile, ... }:
{
  den.aspects.caddy = {
    includes = [ <cloudflare> ];

    nixos =
      {
        config,
        pkgs,
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
          # `pkgs.caddy` resolves to packages/caddy.nix (coraza + security + maxmind plugins).
          package = pkgs.caddy;
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
          '';
        };
      };
  };
}
