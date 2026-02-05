{ config, ... }:
{
  services.cadvisor = {
    enable = true;
    port = 3022;
    extraOptions = [ "--docker_only=false" ];
  };

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 3020;
    webExternalUrl = "/prometheus/";
    checkConfig = true;

    # thanks join
    globalConfig.scrape_interval = "15s";

    exporters = {
      node = {
        enable = true;
        port = 3021;
        enabledCollectors = [ "systemd" ];
      };
      zfs = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9134;
        pools = [ "main" ];
      };
      smartctl = {
        enable = true;
        port = 9633;
        listenAddress = "127.0.0.1";
      };
    };

    scrapeConfigs = [
      {
        job_name = "node_exporter";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
              "100.67.0.1:3021"
            ];
          }
        ];
      }
      {
        job_name = "cadvisor";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.cadvisor.port}"
              "100.67.0.1:3022"
            ];
          }
        ];
      }
      {
        job_name = "loki";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}"
            ];
          }
        ];
      }
      {
        job_name = "promtail";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.promtail.configuration.server.http_listen_port}"
            ];
          }
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}"
            ];
          }
        ];
      }
      {
        job_name = "zfs";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}"
            ];
          }
        ];
      }
      {
        job_name = "comin";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.comin.exporter.port}"
              "100.67.0.1:${toString config.services.comin.exporter.port}"
            ];
          }
        ];
      }
    ];
  };
}
