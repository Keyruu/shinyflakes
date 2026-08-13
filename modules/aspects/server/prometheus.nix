{ ... }:
{
  den.aspects.server.prometheus = {
    nixos = { ... }: {
      # The `scrape` quirk entries are flat attrsets with name, port,
      # scrapePort, metricsPath, interval. Cross-host source info is
      # unavailable without `pipe.withProvenance`; will be re-added once
      # the provenance round-trip works (see notes).
      services.prometheus.scrapeConfigs = [ ];
    };
  };
}
