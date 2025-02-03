{config, ...}: {
  users.groups.alertmanager = {};
  users.users.alertmanager = {
    isSystemUser = true;
    group = "alertmanager";
    extraGroups = ["smtp"];
  };

  services.prometheus = {
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
              # Please add ignored mountpoints in node_exporter parameters like
              # "--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|run)($|/)".
              # Same rule using "node_filesystem_free_bytes" will fire when disk fills for non-root users.
              - alert: HostOutOfDiskSpace
                expr: ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 10 and ON (instance, device, mountpoint) node_filesystem_readonly == 0) * on(instance) group_left (nodename) node_uname_info{nodename=~".+"}
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: Host out of disk space (instance {{ $labels.instance }})
                  description: "Disk is almost full (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
              - alert: HostOutOfMemory
                expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100 < 10) * on(instance) group_left (nodename) node_uname_info{nodename=~".+"}
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: Host out of memory (instance {{ $labels.instance }})
                  description: "Node memory is filling up (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
              - alert: HostSystemdServiceCrashed
                expr: (node_systemd_unit_state{state="failed"} == 1) * on(instance) group_left (nodename) node_uname_info{nodename=~".+"}
                for: 1m
                labels:
                  severity: warning
                annotations:
                  summary: Host systemd service crashed (instance {{ $labels.instance }})
                  description: "systemd service crashed\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
              - alert: BlackboxProbeFailed
                expr: probe_success == 0
                for: 0m
                labels:
                  severity: critical
                annotations:
                  summary: Blackbox probe failed (instance {{ $labels.instance }})
                  description: "Probe failed\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
              - alert: NginxHighHttp5xxErrorRate
                expr: sum(rate(nginx_http_requests_total{status=~"^5.."}[1m])) / sum(rate(nginx_http_requests_total[1m])) * 100 > 5
                for: 1m
                labels:
                  severity: critical
                annotations:
                  summary: Nginx high HTTP 5xx error rate (instance {{ $labels.instance }})
                  description: "Too many HTTP requests with status 5xx (> 5%)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      ''
    ];
  };
}
