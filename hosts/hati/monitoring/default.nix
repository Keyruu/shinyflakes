{config, ...}: {
  imports = [
    ./prometheus.nix
    ./alertmanager.nix
    ./loki.nix
    ./grafana.nix
  ];

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
}
