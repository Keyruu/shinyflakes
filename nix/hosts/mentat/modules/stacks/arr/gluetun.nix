{ config, ... }:
{
  virtualisation.quadlet.containers.torrent-gluetun = {
    containerConfig = {
      image = "ghcr.io/qdm12/gluetun:v3.40.3";
      addCapabilities = [ "NET_ADMIN" ];
      devices = [ "/dev/net/tun:/dev/net/tun" ];
      environments = {
        FIREWALL_VPN_INPUT_PORTS = "53622,15403";
      };
      environmentFiles = [ config.sops.secrets.gluetunEnv.path ];
      publishPorts = [
        "127.0.0.1:8989:8989"
        "127.0.0.1:7878:7878"
        "127.0.0.1:6767:6767"
        # "127.0.0.1:8080:8080"
        "127.0.0.1:8191:8191"
        "127.0.0.1:9696:9696"
        "127.0.0.1:7373:3000"
        "127.0.0.1:5030:5030"
        "127.0.0.1:8686:8686"
      ];
      labels = [
        "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = {
    "sonarr.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8989";
        proxyWebsockets = true;
      };
    };

    "radarr.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:7878";
        proxyWebsockets = true;
      };
    };

    "bazarr.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:6767";
        proxyWebsockets = true;
      };
    };

    # "qbittorrent.lab.keyruu.de" = {
    #   useACMEHost = "lab.keyruu.de";
    #   forceSSL = true;

    #   locations."/" = {
    #     proxyPass = "http://127.0.0.1:8080";
    #     proxyWebsockets = true;
    #   };
    # };

    "prowlarr.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:9696";
        proxyWebsockets = true;
      };
    };

    "flaresolverr.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8191";
        proxyWebsockets = true;
      };
    };

    "rflood.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:7373";
        proxyWebsockets = true;
      };
    };

    "slskd.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:5030";
        proxyWebsockets = true;
      };
    };

    "lidarr.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8686";
        proxyWebsockets = true;
      };
    };
  };
}
