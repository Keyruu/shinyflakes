{config, ...}: {
  services.cadvisor = {
    enable = true;
    port = 3022;
  };

  users.groups.alertmanager = {};
  users.users.alertmanager = {
    isSystemUser = true;
    group = "alertmanager";
    extraGroups = ["smtp"];
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

    alertmanager = {
      enable = true;
      port = 3023;
      checkConfig = true;
      configuration = {
        global = {
          smtp_smarthost = "smtp.resend.com:587";
          smtp_from = "alertmanager@lab.keyruu.de";
          smtp_auth_username = "resend";
          smtp_auth_password_file = config.sops.secrets.resendApiKey.path;
        };

        route = {
          group_by = ["alertname"];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "3h";
          receiver = "me";
          routes = [
            {
              match = {
                severity = "critical";
              };
              receiver = "me";
            }
          ];
        };

        receivers = [
          {
            name = "me";
            email_configs = [
              {
                send_resolved = true;
                to = "me@keyruu.de";
              }
            ];
          }
        ];
      };
    };

    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.alertmanager.port}"];
          }
        ];
      }
    ];

    rules = [
      /*
      yaml
      */
      ''
        groups:
          - name: alertmanager
            rules:
              - alert: InstanceDown
                expr: up == 0
                for: 1m
                labels:
                  severity: critical
                annotations:
                  summary: "Instance {{ $labels.instance }} down"
                  description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute."
      ''
    ];

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
    ];
  };
}
