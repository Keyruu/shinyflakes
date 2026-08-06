{
  flake,
  lib,
  ...
}:
let
  mkEndpoint = cfg: {
    name = cfg.dashboard.title;
    url =
      if cfg.monitor.url != "" then cfg.monitor.url
      else "https://${cfg.domain}${cfg.monitor.healthPath}";
    interval = cfg.monitor.interval;
    conditions = cfg.monitor.conditions;
  };

  endpoints = lib.concatMap
    (cfg: lib.optional (cfg.monitor.enable && cfg.domain != null) (mkEndpoint cfg))
    (lib.attrValues flake.allMyServices);
in
{
  services.gatus = {
    enable = true;
    openFirewall = false;
    settings = {
      web.port = 8044;
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };
      ui = {
        title = "Service Status";
        header = "Uptime monitoring across all hosts";
        logo = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/homepage.png";
        # always show the dashboard, even unauthenticated users (authelia handles auth)
        authentication = { };
        primaryColor = "#6ea8fe";
      };
      inherit endpoints;
    };
  };
}