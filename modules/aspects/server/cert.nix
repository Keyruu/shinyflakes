{ ... }:
{
  den.aspects.server.cert = {
    nixos = { config, ... }: {
      security.acme = {
        defaults.dnsResolver = "1.1.1.1:53";
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
    };
  };
}
