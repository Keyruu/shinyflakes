{
  pkgs,
  config,
  lib,
  ...
}: {
  networking.firewall = let
    allowed = [
      config.services.blocky.settings.ports.http
      config.services.blocky.settings.ports.dns
    ];
  in {
    allowedTCPPorts = allowed;
    allowedUDPPorts = allowed;
  };

  services.postgresql = {
    enable = true;
    authentication = lib.mkForce ''
      local all all trust
    '';
    initialScript = pkgs.writeText "init" ''
      CREATE DATABASE blocky;
      CREATE USER blocky WITH PASSWORD 'blocky';
      GRANT ALL PRIVILEGES ON DATABASE blocky TO blocky;

      \c blocky postgres
      GRANT ALL ON SCHEMA public TO blocky;

      CREATE USER grafana WITH PASSWORD 'grafana';
      GRANT CONNECT ON DATABASE blocky TO grafana;
      GRANT USAGE ON SCHEMA public TO grafana;

      \c blocky blocky
      ALTER DEFAULT PRIVILEGES FOR USER blocky IN SCHEMA public GRANT SELECT ON TABLES TO grafana;
    '';
  };

  services.blocky = {
    enable = true;
    settings = {
      prometheus.enable = true;

      ports = {
        dns = 53;
        http = 4000;
      };

      queryLog = {
        type = "postgresql";
        target = "user=blocky password=blocky host=/run/postgresql dbname=blocky sslmode=disable";
      };

      upstreams = {
        groups = {
          default = [
            # Cloudflare DNS over TLS
            "tcp-tls:1.1.1.1:853"
            "tcp-tls:1.0.0.1:853"
          ];
        };
      };

      customDNS = {
        mapping = {
          "lab.keyruu.de" = "192.168.100.18";
          "immich.keyruu.de" = "192.168.100.18";
        };
      };

      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = ["1.1.1.1" "1.0.0.1"];
      };

      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };

      blocking = {
        loading.refreshPeriod = "12h";

        clientGroupsBlock = {
          default = ["ads" "security"];
        };

        denylists = {
          ads = [
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt"
            "https://blocklistproject.github.io/Lists/ads.txt"
          ];
          security = [
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/tif.medium.txt"
            "https://blocklistproject.github.io/Lists/smart-tv.txt"
          ];
        };

        allowlists = {
          ads = [
            (pkgs.writeText "whitelist.txt" ''
              # this is where whitelisted domains would go
            '')
          ];
        };
      };
    };
  };
}
