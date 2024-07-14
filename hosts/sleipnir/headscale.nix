{
  config,
  pkgs,
  ...
}: {
  services.headscale = {
    enable = true;
    port = 8085;
    settings = {
      server_url = "https://door.keyruu.de:443";
      metrics_listen_addr = "127.0.0.1:8095";
      ip_prefixes = [
        "100.64.0.0/10"
        "fd7a:115c:a1e0::/48"
      ];
      db_type = "sqlite3";
      db_path = "/var/lib/headscale/db.sqlite";
      dns_config = {
        override_local_dns = true;
        base_domain = "door.keyruu.de";
        magic_dns = true;
        nameservers = ["100.64.0.2"];
      };
      unix_socket_permission = "0770";
      disable_check_updates = true;
    };
  };

  services.nginx.virtualHosts."door.keyruu.de" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
      proxyWebsockets = true;
    };
  };
}
