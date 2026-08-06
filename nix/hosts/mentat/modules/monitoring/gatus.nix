{
  config,
  flake,
  lib,
  ...
}:
let
  isInternal =
    domain: lib.hasSuffix ".lab.keyruu.de" domain || lib.hasSuffix ".port.peeraten.net" domain;
  mkEndpoint = cfg: {
    name = cfg.dashboard.title;
    group = if isInternal cfg.domain then "Internal" else "External";
    url =
      if cfg.monitor.url != "" then cfg.monitor.url else "https://${cfg.domain}${cfg.monitor.healthPath}";
    interval = cfg.monitor.interval;
    conditions = cfg.monitor.conditions;
  };

  endpoints = lib.concatMap (
    cfg: lib.optional (cfg.monitor.enable && cfg.domain != null) (mkEndpoint cfg)
  ) (lib.attrValues flake.allMyServices);

  localDomains = lib.concatMap (
    cfg: lib.optional (cfg.proxy.enable && cfg.domain != null && (isInternal cfg.domain)) cfg.domain
  ) (lib.attrValues flake.allMyServices);
in
{
  networking.hosts."127.0.0.1" = localDomains;

  networking.firewall.interfaces.${config.services.mesh.interface}.allowedTCPPorts = [ 8044 ];

  sops = {
    secrets.gatusGotifyToken = { };
    templates."gatus.env" = {
      restartUnits = [ "gatus.service" ];
      content = ''
        GATUS_GOTIFY_TOKEN=${config.sops.placeholder.gatusGotifyToken}
      '';
    };
  };

  services.gatus = {
    enable = true;
    environmentFile = config.sops.templates."gatus.env".path;
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
        logo = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/gatus.png";
        # authelia forward auth gated
        authentication = { };
        primaryColor = "#6ea8fe";
      };
      alerting.gotify = {
        url = "https://notify.keyruu.de";
        token = "\${GATUS_GOTIFY_TOKEN}";
        title = "Gatus";
        default-alert = {
          enabled = true;
          send-on-resolved = true;
        };
      };
      inherit endpoints;
    };
  };
}
