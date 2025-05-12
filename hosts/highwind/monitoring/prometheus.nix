{config, ...}: {
  services.cadvisor = {
    enable = true;
    port = 3022;
    extraOptions = ["--docker_only=false"];
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
        enabledCollectors = ["systemd"];
      };
      zfs = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9134;
        pools = ["main"];
      };
      process = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9256;
      };
      systemd = {
        enable = true;
        port = 9558;
        listenAddress = "127.0.0.1";
      };
      smartctl = {
        enable = true;
        port = 9633;
        listenAddress = "127.0.0.1";
      };
      nginxlog = {
        enable = true;
        port = 3024;
        user = "nginx";
        settings = {
          namespaces = [
            {
              name = "nginx";
              source.files = [
                "/var/log/nginx/access.log"
              ];

              format = ''$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'';

              labels = {
                app = "default";
              };
            }
          ];
        };
      };
    };

    scrapeConfigs = [
      {
        job_name = "node_exporter";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
              "sleipnir:3021"
              "garm:3021"
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
              "sleipnir:3022"
              "garm:3022"
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
        job_name = "nginxlog";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.nginxlog.port}"
            ];
          }
        ];
      }
      {
        job_name = "headscale";
        static_configs = [
          {
            targets = [
              "100.64.0.6:8095"
            ];
          }
        ];
      }
      {
        job_name = "systemd";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.systemd.port}"
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
        job_name = "process";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.process.port}"
            ];
          }
        ];
      }
      {
        job_name = "telegraf";
        static_configs = [
          {
            targets = [
              "127.0.0.1:9273"
            ];
          }
        ];
      }
    ];
  };
}
