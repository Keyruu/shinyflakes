{ config, ... }:
let
  my = config.services.my.adguardhome;
in
{
  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  services = {
    my.adguardhome = {
      enable = true;
      port = 3053;
      domain = "adguard.port.peeraten.net";
    };
    adguardhome = {
      enable = true;
      host = "127.0.0.1";
      inherit (my) port;

      settings = {
        dns = {
          bind_hosts = [
            "192.168.100.7"
            "${config.services.mesh.ip}"
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
              enabled = true;
              domain = "adguard.port.peeraten.net";
              answer = "192.168.100.7";
            }
            {
              enabled = true;
              domain = "monitoring.lab.keyruu.de";
              answer = "192.168.100.7";
            }
            {
              enabled = true;
              domain = "*.lab.keyruu.de";
              answer = "192.168.100.7";
            }
            {
              enabled = true;
              domain = "files.keyruu.de";
              answer = "192.168.100.7";
            }
            {
              enabled = true;
              domain = "*.port.peeraten.net";
              answer = "192.168.100.7";
            }
            {
              enabled = true;
              domain = "hass.peeraten.net";
              answer = "192.168.100.7";
            }
            {
              enabled = true;
              domain = "traccar.peeraten.net";
              answer = "192.168.100.7";
            }
            {
              enabled = true;
              domain = "*.home.zimtix.de";
              answer = "192.168.100.32";
            }
            {
              enabled = true;
              domain = "ubuntu";
              answer = "192.168.100.32";
            }
            {
              enabled = true;
              domain = "teamspeak";
              answer = "192.168.100.32";
            }
            {
              enabled = true;
              domain = "plex.zimtix.de";
              answer = "192.168.100.32";
            }
            {
              enabled = true;
              domain = "nextcloud.zimtix.de";
              answer = "192.168.100.32";
            }
            {
              enabled = true;
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
    nginx.virtualHosts."${my.domain}" = {
      useACMEHost = "port.peeraten.net";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString my.port}";
        proxyWebsockets = true;
      };
    };
  };
}
