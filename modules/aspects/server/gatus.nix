{ lib, ... }:
{
  den.aspects.server.gatus = {
    nixos =
      { config, monitor, ... }:
      let
        isInternal =
          d: lib.hasSuffix ".lab.keyruu.de" d || lib.hasSuffix ".port.peeraten.net" d;

        mkEndpoint = entry: {
          name = entry.name;
          url = if entry.url != null then entry.url else entry.fullUrl;
          inherit (entry) interval conditions;
          group =
            if entry.domain == null then "External"
            else if isInternal entry.domain then "Internal"
            else "External";
          alerts = [ { type = "gotify"; } ];
        };

        endpoints = map mkEndpoint monitor;

        localDomains = lib.concatMap (
          entry: lib.optional (entry.domain != null && isInternal entry.domain) entry.domain
        ) monitor;
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
              server-url = "https://notify.keyruu.de";
              token = "\${GATUS_GOTIFY_TOKEN}";
              title = "Gatus";
              default-alert = {
                enabled = true;
                send-on-resolved = true;
                failure-threshold = 5;
                success-threshold = 5;
              };
            };
            inherit endpoints;
          };
        };
      };
  };
}
