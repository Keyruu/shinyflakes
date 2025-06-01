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
      nginx = lib.mkEnableOption "Enable Nginx logs";

      lokiAddress = lib.mkOption {
        type = lib.types.str;
        default = "http://";
        description = "Loki adress to push logs to";
      };
    };

  };

  config = {
    services.telegraf = {
      enable = true;
      extraConfig = {
        inputs = {
          cpu = {
            percpu = true;
            totalcpu = true;
            collect_cpu_time = false;
            report_active = false;
          };
          disk = {
            mount_points = [ "/" ];
          };
          diskio = {
            devices = [ "*" ];
          };
          net = { };
          mem = { };
          processes = { };
          swap = { };
          system = { };
          netstat = { };
          apcupsd = { };
          docker = {
            endpoint = "unix:///run/podman/podman.sock";
          };
        };
        outputs = {
          prometheus_client = {
            listen = ":9273";
          };
        };
      };
    };

    networking.firewall.interfaces."${cfg.metrics.interface}".allowedTCPPorts = [
      9273
    ];

    users.groups.promtail = { };
    users.groups.nginx = lib.mkIf cfg.logs.nginx { };
    users.users.promtail = {
      isSystemUser = true;
      group = "promtail";
      extraGroups = [ (lib.mkIf cfg.logs.nginx "nginx") ];
    };

    services.promtail = lib.mkIf cfg.logs.enable {
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
          (lib.mkIf cfg.logs.nginx {
            job_name = "nginx";
            static_configs = [
              {
                labels = {
                  job = "nginx";
                  __path__ = "/var/log/nginx/*.log";
                  host = config.networking.hostName;
                  instance = config.networking.hostName;
                };
              }
            ];
          })
        ];
      };
    };
  };
}
