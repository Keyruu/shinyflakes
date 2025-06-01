{ config, ... }:
let
  speedtestTrackerPath = "/etc/stacks/speedtest-tracker/config";
in
{
  systemd.tmpfiles.rules = [
    "d ${speedtestTrackerPath} 0755 1000 1000"
  ];

  sops = {
    secrets."speedtestTrackerAppKey".owner = "root";
    templates."speedtest-tracker.env".content = # env
      ''
        APP_KEY=${config.sops.placeholder.speedtestTrackerAppKey}
        SPEEDTEST_SCHEDULE=3,33 * * * *
      '';
  };

  virtualisation.quadlet.containers.speedtest-tracker = {
    containerConfig = {
      image = "lscr.io/linuxserver/speedtest-tracker:latest";
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
        "127.0.0.1:9122:80"
      ];
      volumes = [
        "${speedtestTrackerPath}:/config"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts."speedtest.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:9122";
      proxyWebsockets = true;
    };
  };
}
