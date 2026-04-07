{ config, ... }:
{
  networking.firewall.interfaces = {
    "eth0".allowedTCPPorts = [ config.services.loki.configuration.server.http_listen_port ];
    "${config.services.mesh.interface}".allowedTCPPorts = [
      config.services.loki.configuration.server.http_listen_port
    ];
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
}
