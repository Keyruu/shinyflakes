{
  config,
  flake,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    flake.modules.services.caddy
  ];

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
      corazaCaddyVersion = "v2.1.1-0.20251210234215-5d280fbd8128";

      inherit (flake.lib.cloudflare) all;
    in
    {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/corazawaf/coraza-caddy/v2@${corazaCaddyVersion}"
        ];
        hash = "sha256-ahvwwSb+LDX3hUb4rVHy3ItMZTDPQSZm9JfZbl50L4c=";
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
