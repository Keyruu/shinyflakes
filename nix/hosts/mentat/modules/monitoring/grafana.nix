{
  config,
  inputs,
  pkgs,
  ...
}:
let
  smallPkgs = import inputs.nixpkgs-small { inherit (pkgs) system; };
in
{
  environment.etc."grafana/dashboards" = {
    source = ./dashboards;
    user = "grafana";
    group = "grafana";
  };

  # Create a home dashboard that lists all dashboards
  environment.etc."grafana/home.json".text = builtins.toJSON {
    title = "Home";
    uid = "home";
    editable = false;
    hideControls = false;
    panels = [
      {
        id = 1;
        type = "dashlist";
        title = "Dashboards";
        gridPos = {
          h = 20;
          w = 24;
          x = 0;
          y = 0;
        };
        options = {
          showSearch = true;
          showStarred = false;
          showRecentlyViewed = false;
          showHeadings = true;
          maxItems = 100;
          query = "";
          tags = [ ];
        };
      }
    ];
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

      # Disable alerting to simplify UI
      alerting.enabled = false;
      unified_alerting.enabled = false;

      # Simplify the navigation menu
      navigation = {
        app_standalone_pages = false;
      };

      # Disable features not needed
      explore.enabled = false;

      # Set default home dashboard to the dashboard list
      dashboards = {
        default_home_dashboard_path = "/etc/grafana/home.json";
      };

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
