{ lib, ... }:
{
  den.aspects.server.prometheus = {
    nixos = { scrape, ... }:
    let
      jobs = lib.map (entry:
        let value = entry.value; in {
          job_name = "${entry.source.host.name}-${value.service or "default"}";
          targets = [ "${entry.source.host.addr}:${toString value.port}" ];
          metricsPath = value.metricsPath;
          scrape_interval = value.interval or "15s";
        }
      ) scrape;
    in
    {
      services.prometheus.scrapeConfigs = jobs;
    };
  };
}
