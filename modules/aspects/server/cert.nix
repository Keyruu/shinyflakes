{ ... }:
{
  den.aspects.server.cert = {
    nixos = { config, ... }: {
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
          # Port 8448 (federation) + matrix-rtc (lk-jwt-service) need a
          # publicly-trusted cert that the lk-jwt-service HTTP client
          # can verify out of the box. NixOS issues via Cloudflare DNS-01
          # and stores at /var/lib/acme/matrix.peeraten.net/ for caddy.
          "matrix.peeraten.net" = {
            extraDomainNames = [ "matrix-rtc.peeraten.net" ];
            dnsProvider = "cloudflare";
            dnsPropagationCheck = true;
            environmentFile = config.sops.secrets.cloudflare.path;
          };
        };
      };
    };
  };
}
