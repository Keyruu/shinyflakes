{config, ...}: {
  security.acme = {
    certs = {
      "lab.keyruu.de" = {
        extraDomainNames = [ "*.lab.keyruu.de" ];
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        environmentFile = config.sops.secrets.cloudflare.path;
      };
      "port.peeraten.net" = {
        extraDomainNames = [ "*.port.peeraten.net" ];
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        environmentFile = config.sops.secrets.cloudflare.path;
      };
    };
  };
}
