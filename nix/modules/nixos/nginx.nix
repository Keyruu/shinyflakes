{ config, ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "me@keyruu.de";
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    resolver.addresses = config.networking.nameservers;
    sslDhparam = true;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  users.users.nginx.extraGroups = [ "acme" ];
}
