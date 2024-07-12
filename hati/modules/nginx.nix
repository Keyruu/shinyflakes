{config, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "me@keyruu.de";

    certs."lab.keyruu.de" = {
      domain = "lab.keyruu.de";
      extraDomainNames = [ "*.lab.keyruu.de" ];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      credentialsFile = config.sops.secrets.cloudflare.path;
    };
  };

  security.dhparams = {
    enable = true;
    params.nginx = {};
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    resolver.addresses = config.networking.nameservers;
    sslDhparam = config.security.dhparams.params.nginx.path;
  };

  users.users.nginx.extraGroups = [ "acme" ];
}
