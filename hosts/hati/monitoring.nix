{config, ...}: {
  services.cadvisor = {
    enable = true;
    port = 3022;
  };
   
  services.prometheus = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 3020;
    webExternalUrl = "/prometheus/";
    checkConfig = true;

    exporters = {
      node = {
        enable = true;
        port = 3021;
        enabledCollectors = ["systemd"];
      };
    };

    scrapeConfigs = [
      {
        job_name = "nodes";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
      {
        job_name = "cadvisor";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.cadvisor.port}"];
          }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3030;
      auth_enabled = false;

      common = {
        replication_factor = 1;
        path_prefix = "/tmp/loki";
        ring = {
          kvstore.store = "inmemory";
          instance_addr = "127.0.0.1";
        };
      };

      schema_config = {
        configs = [{
          from = "2020-05-15";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
      };

      storage_config.filesystem.directory = "/tmp/loki/chunks";
    };
  };

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
      }];
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = "pihole";
          };
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }];
    };
    # extraFlags
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3010;
      };
      
      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };
    };


    provision = {
      enable = true;
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
      ];
    };
  };

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
