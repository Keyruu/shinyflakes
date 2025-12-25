{ pkgs, ... }:
{
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
        hash = "sha256-zGUfWcobpf4r9/7HKomsSvrjijsDwnj+YHW30TT6WlQ=";
      };

      globalConfig = ''
        order coraza_waf first
      '';
    };
}
