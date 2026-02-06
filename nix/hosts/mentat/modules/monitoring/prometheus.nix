{ config, lib, ... }:
let
  hosts = {
    mentat = "127.0.0.1";
    prime = "100.67.0.1";
  };

  exporters = {
    node_exporter = {
      mentat = config.services.prometheus.exporters.node.port;
      prime = 3021;
    };
    cadvisor = {
      mentat = config.services.cadvisor.port;
      prime = 3022;
    };
    comin = {
      mentat = config.services.comin.exporter.port;
      prime = 4243;
    };
    loki = {
      mentat = config.services.loki.configuration.server.http_listen_port;
    };
    promtail = {
      mentat = config.services.promtail.configuration.server.http_listen_port;
    };
    smartctl = {
      mentat = config.services.prometheus.exporters.smartctl.port;
    };
    zfs = {
      mentat = config.services.prometheus.exporters.zfs.port;
    };
  };

  mkScrapeConfig = jobName: hostPorts: {
    job_name = jobName;
    static_configs = lib.mapAttrsToList (hostName: port: {
      targets = [ "${hosts.${hostName}}:${toString port}" ];
      labels.hostname = hostName;
    }) hostPorts;
  };
in
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

    scrapeConfigs = lib.mapAttrsToList mkScrapeConfig exporters;
  };
}
