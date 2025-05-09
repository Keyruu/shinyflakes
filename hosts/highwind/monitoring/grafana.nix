{
  config,
  inputs,
  pkgs,
  ...
}:let
  smallPkgs = import inputs.nixpkgs-small { inherit (pkgs) system; };
in
{
  environment.etc."grafana/dashboards" = {
    source = ./dashboards;
    user = "grafana";
    group = "grafana";
  };

  services.grafana = {
    enable = true;
    package = smallPkgs.grafana;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3010;
      };

      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };
      panels.disable_sanitize_html = true;

      feature_toggles = {
        provisioning = true;
        kubernetesDashboards = true;
      };
    };

    provision = {
      enable = true;
      dashboards.settings.providers = [
        {
          options.path = "/etc/grafana/dashboards";
        }
      ];
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}/prometheus";
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
        {
          name = "postgresql-blocky";
          type = "postgres";
          url = "/run/postgresql";
          user = "grafana";
          jsonData = {
            password = "grafana";
            database = "blocky";
            sslmode = "disable";
          };
        }
      ];
    };
  };
}
