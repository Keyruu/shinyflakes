{
  flake,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    flake.modules.services.caddy
  ];

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

      ipv4Txt = builtins.fetchurl {
        url = "https://www.cloudflare.com/ips-v4";
        sha256 = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
      };

      ipv6Txt = builtins.fetchurl {
        url = "https://www.cloudflare.com/ips-v6";
        sha256 = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
      };

      parseIpList =
        txt:
        lib.pipe txt [
          builtins.readFile
          (lib.splitString "\n")
          (lib.filter (ip: ip != ""))
        ];

      ipv4 = parseIpList ipv4Txt;
      ipv6 = parseIpList ipv6Txt;

      ips = ipv4 ++ ipv6;
    in
    {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/corazawaf/coraza-caddy/v2@${corazaCaddyVersion}"
        ];
        hash = "sha256-7mqh9RM6jyGEatxCTBY2iJqvYmbP2ltxSAZ8Y08on8M=";
      };

      globalConfig = ''
        order coraza_waf first
        servers {
          trusted_proxies static ${lib.concatStringsSep " " ips}
          trusted_proxies_strict
          client_ip_headers Cf-Connecting-Ip X-Forwarded-For
        }
      '';

      extraConfig = ''
        (cloudflare-only) {
          @not-cloudflare {
            not remote_ip ${lib.concatStringsSep " " ips}
          }
          respond @not-cloudflare 403
        }
      '';
    };
}
