{
  config,
  flake,
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

  services.caddy =
    let
      # renovate: datasource=go depName=github.com/corazawaf/coraza-caddy/v2
      corazaCaddyVersion = "v2.2.0";

      inherit (flake.lib.cloudflare) all;
    in
    {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/corazawaf/coraza-caddy/v2@${corazaCaddyVersion}"
        ];
        hash = "sha256-e/GdUZ5IOKHvP83uLk4EH6oUROV7s0q8LF4b+Y3wook=";
      };

      environmentFile = config.sops.templates."caddy.env".path;

      globalConfig = ''
        order coraza_waf first
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
