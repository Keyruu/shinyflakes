{config, ...}: {
  services.headscale = {
    enable = true;
    port = 8085;
    settings = {
      server_url = "https://headscale.peeraten.net:443";
      metrics_listen_addr = "100.64.0.6:8095";
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
        nameservers.global = [
          "100.64.0.1"
        ];
      };
    };
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  services.nginx.virtualHosts."headscale.peeraten.net" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
      proxyWebsockets = true;
    };
  };
}
