{ config, ... }:
{
  sops.secrets.frpToken = {
    restartUnits = [ "frp.service" ];
    mode = "0444";
  };

  networking.firewall.interfaces.mesh0.allowedTCPPorts = [ 7000 ];

  services.frp = {
    enable = true;
    role = "server";
    settings = {
      bindAddr = "100.67.0.1";
      bindPort = 7000;
      proxyBindAddr = "127.0.0.1";
      vhostHTTPPort = 8023;
      subDomainHost = "tunnel.peeraten.net";
      auth.method = "token";
      auth.tokenSource = {
        type = "file";
        file.path = config.sops.secrets.frpToken.path;
      };
      log.to = "console";
      log.level = "info";
    };
  };

  security.acme.certs."tunnel.peeraten.net" = {
    group = "caddy";
    extraDomainNames = [ "*.tunnel.peeraten.net" ];
    dnsProvider = "cloudflare";
    dnsPropagationCheck = true;
    environmentFile = config.sops.secrets.cloudflare.path;
  };

  services.caddy.virtualHosts."*.tunnel.peeraten.net" = {
    extraConfig = ''
      tls ${config.security.acme.certs."tunnel.peeraten.net".directory}/fullchain.pem ${
        config.security.acme.certs."tunnel.peeraten.net".directory
      }/key.pem
      reverse_proxy http://127.0.0.1:8023
    '';
  };
}
