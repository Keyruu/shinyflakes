{ config, lib, ... }:
let
  my = config.services.my."blocky-ui";

  mentat = "192.168.100.7";
  desktop = "192.168.100.32";
  router = "192.168.100.1";

  apiPort = 4000;
  queryLogDir = "/var/log/blocky";

  allowed = ''
    pixeldrain.com
    cdn.discordapp.com
    developers.didomi.io
    # Firefox Web Push routes through Mozilla AutoPush; hagezi/blocklistproject
    # block these as telemetry, breaking push for clients on this resolver.
    # Covers updates.push.services.mozilla.com as a subdomain.
    push.services.mozilla.com
  '';
in
{
  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  # DynamicUser puts LogsDirectory under /var/log/private (0700, root-owned),
  # which blocky-ui cannot read even with world-readable log files.
  users.users.blocky = {
    isSystemUser = true;
    group = "blocky";
  };
  users.groups.blocky = { };

  systemd.services.blocky.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "blocky";
    Group = "blocky";
  };

  services.blocky = {
    enable = true;
    settings = {
      ports = {
        dns = [
          "${mentat}:53"
          "${config.services.mesh.ip}:53"
        ];
        http = apiPort;
        # mesh0 is brought up by wg-quick, which blocky.service is not ordered
        # after, so 100.67.0.2 may not exist yet at start (and disappears on a
        # mesh0 restart). Without freeBind that bind fails and the unit dies.
        freeBind = true;
      };

      prometheus.enable = true;

      queryLog = {
        type = "csv-client";
        target = queryLogDir;
        logRetentionDays = 7;
      };

      upstreams.groups.default = [ "https://cloudflare-dns.com/dns-query" ];
      bootstrapDns = [ "tcp+udp:1.1.1.1" ];

      customDNS.mapping = {
        # covers monitoring.lab.keyruu.de and every other *.lab.keyruu.de
        "lab.keyruu.de" = mentat;
        "port.peeraten.net" = mentat;
        "files.keyruu.de" = mentat;
        "cache.keyruu.de" = mentat;
        "hass.peeraten.net" = mentat;
        "traccar.peeraten.net" = mentat;
        "tv.peeraten.net" = mentat;

        "home.zimtix.de" = desktop;
        "plex.zimtix.de" = desktop;
        "nextcloud.zimtix.de" = desktop;
        "gitea.zimtix.de" = desktop;
        ubuntu = desktop;
        teamspeak = desktop;
      };

      # rDNS against the router so the UI shows hostnames instead of bare IPs
      clientLookup.upstream = router;

      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };

      blocking = {
        loading.refreshPeriod = "12h";

        clientGroupsBlock.default = [
          "ads"
          "security"
        ];

        denylists = {
          ads = [ "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt" ];
          security = [
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/tif.medium.txt"
            "https://blocklistproject.github.io/Lists/smart-tv.txt"
          ];
        };

        allowlists = {
          ads = [ allowed ];
          security = [ allowed ];
        };
      };
    };
  };

  services.my."blocky-ui" = {
    port = 3053;
    domain = "blocky.port.peeraten.net";
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
    stack = {
      enable = true;
      security.enable = true;

      containers.blocky-ui = {
        containerConfig = {
          image = "ghcr.io/gabeduartem/blocky-ui:2.0.0";
          publishPorts = [ "127.0.0.1:${toString my.port}:3000" ];
          volumes = [ "${queryLogDir}:/logs:ro" ];
          # blocky listens on the host, not in a container network
          addHosts = [ "host.containers.internal:host-gateway" ];
          environments = {
            TZ = "Europe/Berlin";
            BLOCKY_API_URL = "http://host.containers.internal:${toString apiPort}";
            QUERY_LOG_TYPE = "csv-client";
            QUERY_LOG_TARGET = "/logs/";
          };
        };
        # Next.js standalone writes its fetch cache to /app/.next/cache
        security.readOnlyRootFilesystem = false;
        unitConfig = {
          After = [ "blocky.service" ];
          Wants = [ "blocky.service" ];
        };
      };
    };
  };
}
