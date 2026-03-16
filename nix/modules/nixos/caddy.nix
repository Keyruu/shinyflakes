{
  config,
  flake,
  perSystem,
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

  services.caddy =
    let
      inherit (flake.lib.cloudflare) all;
    in
    {
      enable = true;
      package = perSystem.self.caddy;
      environmentFile = config.sops.templates."caddy.env".path;

      logDir = "/var/log/caddy";

      globalConfig = ''
        order coraza_waf first
        log default {
          output file /var/log/caddy/access.log {
            roll_size 100MiB
            roll_keep 5
            roll_keep_for 168h
          }
          format json
          level INFO
        }
        servers {
          trusted_proxies static ${lib.concatStringsSep " " all}
          trusted_proxies_strict
          client_ip_headers Cf-Connecting-Ip X-Forwarded-For
        }
      '';

      extraConfig = ''
        (cloudflare-only) {
          @not-cloudflare {
            not remote_ip ${lib.concatStringsSep " " all}
          }
          respond @not-cloudflare 403
        }
      '';
    };
}
