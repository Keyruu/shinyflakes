{ lib, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "me@keyruu.de";
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/corazawaf/coraza-caddy/v2@v2.1.0"
      ];
      hash = "sha256-6JOU5HA6Y1kvylQ8Xm3d3vzuFby6vL4W4Ncap7/iW2A=";
    };

    globalConfig = ''
      order coraza_waf first
    '';
  };
}
