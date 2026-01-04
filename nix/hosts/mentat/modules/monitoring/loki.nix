{
  hostName,
  config,
  ...
}:
{
  networking.firewall.interfaces = {
    "eth0".allowedTCPPorts = [ config.services.loki.configuration.server.http_listen_port ];
    "portal0".allowedTCPPorts = [ config.services.loki.configuration.server.http_listen_port ];
  };

  services.loki = {
    enable = true;
    configuration = {
      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = 3030;
      };
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
        configs = [
          {
            from = "2020-05-15";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      storage_config.filesystem.directory = "/tmp/loki/chunks";

      analytics.reporting_enabled = false;
    };
  };

  users = {
    groups = {
      promtail = { };
      nginx = { };
    };
    users.promtail = {
      isSystemUser = true;
      group = "promtail";
      extraGroups = [ "nginx" ];
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
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = hostName;
              instance = "127.0.0.1";
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
          ];
        }
        {
          job_name = "nginx";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "nginx";
                __path__ = "/var/log/nginx/*.log";
                host = hostName;
                instance = "127.0.0.1";
              };
            }
          ];
        }
      ];
    };
    # extraFlags
  };
}
