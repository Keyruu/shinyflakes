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
            ];
          }
        ];
      }
      {
        job_name = "blocky";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.blocky.settings.ports.http}"
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
    ];
  };
}
