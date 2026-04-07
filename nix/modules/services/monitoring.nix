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
        description = "Loki address to push logs to (http://host:port)";
      };
    };
  };

  config = {
    networking.firewall.interfaces."${cfg.metrics.interface}".allowedTCPPorts = [
      config.services.prometheus.exporters.node.port
      config.services.cadvisor.port
      config.services.comin.exporter.port
    ];

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

      fluent-bit = lib.mkIf cfg.logs.enable {
        enable = true;
        settings = {
          service = {
            flush = 5;
            log_level = "info";
          };
          pipeline = {
            inputs = [
              {
                name = "systemd";
                tag = "host.journal";
                read_from_tail = true;
              }
            ];
            filters = [
              {
                name = "modify";
                match = "host.journal";
                Copy = [ "_SYSTEMD_UNIT unit" ];
                Add = [
                  "job systemd-journal"
                  "hostname ${config.networking.hostName}"
                  "instance ${cfg.logs.instance}"
                ];
              }
              {
                name = "record_modifier";
                match = "host.journal";
                allowlist_key = [
                  "MESSAGE"
                  "unit"
                  "job"
                  "hostname"
                  "instance"
                ];
              }
            ];
            outputs = [
              (
                let
                  parts = builtins.match "http://([^:]+):([0-9]+)" cfg.logs.lokiAddress;
                in
                {
                  name = "loki";
                  match = "*";
                  host = builtins.elemAt parts 0;
                  port = lib.toInt (builtins.elemAt parts 1);
                  label_keys = "$hostname,$job,$unit,$instance";
                  drop_single_key = "raw";
                  line_format = "json";
                }
              )
            ];
          };
        };
      };
    };
  };
}
