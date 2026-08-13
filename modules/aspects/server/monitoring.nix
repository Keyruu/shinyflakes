{ den, ... }:
{
  den.aspects.server.monitoring = {
    includes = [
      den.aspects.server.prometheus
      den.aspects.server.alertmanager
      den.aspects.server.loki
      den.aspects.server.grafana
      den.aspects.server.beszel-hub
      den.aspects.server.gatus
    ];

    nixos = { config, ... }: {
      services.nginx.virtualHosts."monitoring.lab.keyruu.de" = {
        useACMEHost = "lab.keyruu.de";
        forceSSL = true;
        locations."/prometheus/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
        };

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
