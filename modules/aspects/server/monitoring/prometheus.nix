{ ... }:
{
  den.aspects.server.prometheus =
    let
      hostIp = config: config.services.mesh.ip or null;
    in
    {
      nixos =
        {
          lib,
          scrape,
          ...
        }:
        {
          services.prometheus = {
            enable = lib.mkDefault true;
            listenAddress = "127.0.0.1";
            port = 3020;
            webExternalUrl = "/prometheus/";
            checkConfig = true;
            # thanks join
            globalConfig.scrape_interval = "15s";

            exporters = {
              zfs = {
                enable = lib.mkDefault true;
                listenAddress = "127.0.0.1";
                port = 9134;
                pools = [ "main" ];
              };
              smartctl = {
                enable = lib.mkDefault true;
                port = 9633;
                listenAddress = "127.0.0.1";
              };
            };

            scrapeConfigs =
              let
                grouped = lib.groupBy (e: e.name) scrape;
              in
              lib.mapAttrsToList (name: entries: {
                job_name = name;
                metrics_path = (builtins.head entries).metricsPath;
                scrape_interval = (builtins.head entries).interval;
                static_configs = [
                  {
                    targets = lib.concatMap (e: [
                      "${if e.hostIp != null then e.hostIp else "127.0.0.1"}:${toString e.scrapePort}"
                    ]) entries;
                  }
                ];
              }) grouped;
          };
        };

      # Emit scrape entries for the exporters we set up here. The quirk only
      # fires when this aspect is included, so no host without zfs/smartctl
      # sees these entries.
      scrape =
        { config, ... }:
        [
          {
            name = "zfs";
            metricsPath = "/metrics";
            interval = "15s";
            scrapePort = config.services.prometheus.exporters.zfs.port;
            hostIp = hostIp config;
          }
          {
            name = "smartctl";
            metricsPath = "/metrics";
            interval = "15s";
            scrapePort = config.services.prometheus.exporters.smartctl.port;
            hostIp = hostIp config;
          }
        ];
    };
}
