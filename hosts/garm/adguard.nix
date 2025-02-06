{ config, ... }:
{
  networking.firewall =
    let
      allowed = [
        53
      ];
    in
    {
      allowedTCPPorts = allowed;
      allowedUDPPorts = allowed;
    };

  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    port = 3000;

    settings = {
      dns = {
        bind_hosts = [
          "0.0.0.0"
        ];
        port = 53;
        upstream_dns = [
          "https://cloudflare-dns.com/dns-query"
        ];
        bootstrap_dns = [
          "1.1.1.1"
        ];
        fallback_dns = [
          "192.168.100.1"
        ];
      };
      filtering = {
        rewrites = [
          {
            domain = "adguard.port.peeraten.net";
            answer = "192.168.100.5";
          }
          {
            domain = "monitoring.lab.keyruu.de";
            answer = "192.168.100.7";
          }
          {
            domain = "*.lab.keyruu.de";
            answer = "192.168.100.7";
          }
          {
            domain = "*.port.peeraten.net";
            answer = "192.168.100.7";
          }
          {
            domain = "hass.peeraten.net";
            answer = "192.168.100.7";
          }
          {
            domain = "traccar.peeraten.net";
            answer = "192.168.100.7";
          }
          {
            domain = "*.home.zimtix.de";
            answer = "192.168.100.32";
          }
          {
            domain = "ubuntu";
            answer = "192.168.100.32";
          }
          {
            domain = "teamspeak";
            answer = "192.168.100.32";
          }
          {
            domain = "plex.zimtix.de";
            answer = "192.168.100.32";
          }
          {
            domain = "nextcloud.zimtix.de";
            answer = "192.168.100.32";
          }
          {
            domain = "gitea.zimtix.de";
            answer = "192.168.100.32";
          }
        ];
      };
      filters = [
        {
          enabled = true;
          url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt";
          name = "ads/hagezi";
          id = 1;
        }
        {
          enabled = true;
          url = "https://blocklistproject.github.io/Lists/adguard/ads-ags.txt";
          name = "ads/blocklistproject";
          id = 2;
        }
        {
          enabled = false;
          url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/tif.medium.txt";
          name = "security/hagezi";
          id = 3;
        }
        {
          enabled = true;
          url = "https://blocklistproject.github.io/Lists/adguard/abuse-ags.txt";
          name = "abuse/blocklistproject";
          id = 4;
        }
        {
          enabled = true;
          url = "https://blocklistproject.github.io/Lists/adguard/phishing-ags.txt";
          name = "phishing/blocklistproject";
          id = 5;
        }
        {
          enabled = true;
          url = "https://blocklistproject.github.io/Lists/adguard/scam-ags.txt";
          name = "scam/blocklistproject";
          id = 6;
        }
        {
          enabled = true;
          url = "https://blocklistproject.github.io/Lists/adguard/tracking-ags.txt";
          name = "tracking/blocklistproject";
          id = 7;
        }
        {
          enabled = true;
          url = "https://blocklistproject.github.io/Lists/adguard/ransomware-ags.txt";
          name = "ransomeware/blocklistproject";
          id = 8;
        }
      ];
    };
  };

  security.acme = {
    certs."adguard" = {
      domain = "adguard.port.peeraten.net";
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.nginx.virtualHosts."adguard.port.peeraten.net" = {
    useACMEHost = "adguard";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.adguardhome.port}";
      proxyWebsockets = true;
    };
  };
}
