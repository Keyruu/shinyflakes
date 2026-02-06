{ config, lib, ... }:
let
  cfg = config.services.monitoring;
in
{
  options.services.monitoring = {
    metrics = {
      enable = lib.mkEnableOption "Expose metrics";
      interface = lib.mkOption {
        type = lib.types.str;
        default = "eth0";
        description = "The interface for metrics firewall rule";
      };
    };

    logs = {
      enable = lib.mkEnableOption "Push logs";
      instance = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "instance label to identify machine";
      };

      lokiAddress = lib.mkOption {
        type = lib.types.str;
        default = "http://";
        description = "Loki adress to push logs to";
      };
    };
  };

  config = {
    networking.firewall.interfaces."${cfg.metrics.interface}".allowedTCPPorts = [
      config.services.prometheus.exporters.node.port
      config.services.cadvisor.port
      config.services.comin.exporter.port
    ];

    users = {
      groups.promtail = { };
      users.promtail = {
        isSystemUser = true;
        group = "promtail";
      };
    };

    services = {
      cadvisor = {
        enable = true;
        listenAddress = "0.0.0.0";
        port = 3022;
        extraOptions = [ "--docker_only=false" ];
      };

      comin.exporter = {
        listen_address = "0.0.0.0";
        port = 4243;
      };

      prometheus.exporters = lib.mkIf cfg.metrics.enable {
        node = {
          enable = true;
          enabledCollectors = [
            "systemd"
            "cgroups"
            "processes"
          ];
          port = 3021;
        };
      };

      promtail = lib.mkIf cfg.logs.enable {
        enable = true;
        configuration = {
          # We have no need for the HTTP or GRPC server
          server.disable = true;

          clients = [ { url = "${cfg.logs.lokiAddress}/loki/api/v1/push"; } ];

          scrape_configs = [
            {
              job_name = "journal";
              journal = {
                max_age = "12h";
                labels = {
                  job = "systemd-journal";
                  host = config.networking.hostName;
                  instance = config.networking.hostName;
                };
              };

              relabel_configs = [
                {
                  source_labels = [ "__journal__systemd_unit" ];
                  target_label = "unit";
                }
              ];
            }
          ];
        };
      };
    };
  };
}
