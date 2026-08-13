{ lib, ... }:
{
  den.aspects.server.prometheus = {
    nixos = { scrape, ... }: {
      # Each quirk entry carries name, scrapePort, metricsPath, interval,
      # and hostIp (producing host's mesh IP). LAN-only hosts have
      # hostIp = null → target 127.0.0.1.
      services.prometheus.scrapeConfigs = map (entry: {
        job_name = entry.name;
        metrics_path = entry.metricsPath;
        scrape_interval = entry.interval;
        static_configs = [
          {
            targets = [
              "${if entry.hostIp != null then entry.hostIp else "127.0.0.1"}:${toString entry.scrapePort}"
            ];
          }
        ];
      }) scrape;
    };
  };
}
