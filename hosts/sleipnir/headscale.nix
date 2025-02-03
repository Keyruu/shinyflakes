{ config, ... }:
{
  services.headscale = {
    enable = true;
    port = 8085;
    settings = {
      server_url = "https://headscale.peeraten.net:443";
      metrics_listen_addr = "0.0.0.0:8095";
      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
      };
      database = {
        type = "sqlite3";
        sqlite.path = "/var/lib/headscale/db.sqlite";
      };
      dns = {
        override_local_dns = true;
        base_domain = "hafen.peeraten.net";
        magic_dns = true;
        nameservers.split = {
          "lab.keyruu.de" = [
            "100.64.0.13"
          ];
          "home.zimtix.de" = [
            "100.64.0.13"
          ];
          "port.peeraten.net" = [
            "100.64.0.13"
          ];
        };
      };
      oidc = {
        only_start_if_oidc_is_available = false;
        issuer = "https://auth.peeraten.net/oauth2/openid/headscale";
        client_id = "headscale";
        client_secret_path = config.sops.secrets.headscaleOidc.path;
        scope = [
          "openid"
          "profile"
          "email"
        ];
      };
    };
  };

  virtualisation.quadlet.containers.headplane = {
    containerConfig = {
      image = "ghcr.io/tale/headplane:0.3.9";
      publishPorts = [ "127.0.0.1:3000:3000" ];
      environments = {
        HEADSCALE_URL = "https://headscale.peeraten.net";
      };
      environmentFiles = [
        config.sops.secrets.headplaneEnv.path
      ];
    };
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    authKeyFile = config.sops.secrets.headscaleAuthKey.path;
    extraUpFlags = [
      "--login-server=https://headscale.peeraten.net"
      "--accept-routes=true"
    ];
  };

  services.nginx.virtualHosts."headscale.peeraten.net" = {
    enableACME = true;
    forceSSL = true;

    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
        proxyWebsockets = true;
      };
      "/admin" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
      };
    };
  };
}
