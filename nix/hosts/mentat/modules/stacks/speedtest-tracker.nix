{ config, flake, ... }:
let
  my = config.services.my.speedtest-tracker;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets."speedtestTrackerAppKey".owner = "root";

  sops.templates."speedtest-tracker.env" = {
    restartUnits = [ (quadlet.service containers.speedtest-tracker) ];
    content = # env
      ''
        APP_KEY=${config.sops.placeholder.speedtestTrackerAppKey}
        SPEEDTEST_SCHEDULE=3,33 * * * *
      '';
  };

  services.my.speedtest-tracker = {
    port = 9122;
    domain = "speedtest.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        {
          path = "config";
          mode = "0755";
          owner = "1000";
          group = "1000";
        }
      ];
      security.enable = false;

      containers = {
        speedtest-tracker = {
          containerConfig = {
            image = "lscr.io/linuxserver/speedtest-tracker:1.13.11";
            environments = {
              TZ = "Europe/Berlin";
              PUID = "1000";
              PGID = "1000";
              DB_CONNECTION = "sqlite";
            };
            environmentFiles = [
              config.sops.templates."speedtest-tracker.env".path
            ];
            volumes = [
              "${my.stack.path}/config:/config"
            ];
          };
        };
      };
    };
  };
}
