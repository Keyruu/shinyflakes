{config, ...}: {
  security.acme = {
    certs."lab.keyruu.de" = {
      domain = "lab.keyruu.de";
      extraDomainNames = [ "*.lab.keyruu.de" ];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };
}
