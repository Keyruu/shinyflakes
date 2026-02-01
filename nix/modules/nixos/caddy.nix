{ flake, pkgs, ... }:
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
      '';
    };
}
