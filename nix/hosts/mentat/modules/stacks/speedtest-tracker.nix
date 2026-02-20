{ config, ... }:
let
  stackPath = "/etc/stacks/speedtest-tracker/config";
  my = config.services.my.speedtest-tracker;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath} 0755 1000 1000"
  ];

  sops = {
    secrets."speedtestTrackerAppKey".owner = "root";
    templates."speedtest-tracker.env" = {
      restartUnits = [ "speedtest-tracker.service" ];
      content = # env
        ''
          APP_KEY=${config.sops.placeholder.speedtestTrackerAppKey}
          SPEEDTEST_SCHEDULE=3,33 * * * *
        '';
    };
  };

  services.my.speedtest-tracker = {
    port = 9122;
    domain = "speedtest.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
    };
  };

  virtualisation.quadlet.containers.speedtest-tracker = {
    containerConfig = {
      image = "lscr.io/linuxserver/speedtest-tracker:1.13.10";
      environments = {
        TZ = "Europe/Berlin";
        PUID = "1000";
        PGID = "1000";
        DB_CONNECTION = "sqlite";
      };
      environmentFiles = [
        config.sops.templates."speedtest-tracker.env".path
      ];
      publishPorts = [
        "127.0.0.1:${toString my.port}:80"
      ];
      volumes = [
        "${stackPath}:/config"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
