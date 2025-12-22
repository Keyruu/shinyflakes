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
        "github.com/corazawaf/coraza-caddy/v2@5d280fbd812859e8f5a947a0b1c6b1b9b555c6d5"
      ];
      hash = "sha256-zGUfWcobpf4r9/7HKomsSvrjijsDwnj+YHW30TT6WlQ=";
    };

    globalConfig = ''
      order coraza_waf first
    '';
  };
}
