{ ... }:
{
  den.aspects.services.speedtest-tracker = {
    nixos = { config, ... }:
      let
        my = config.services.my.speedtest-tracker;
      in
      {
        sops.secrets."speedtestTrackerAppKey".owner = "root";

        sops.templates."speedtest-tracker.env" = {
          restartUnits = [ "speedtest-tracker.service" ];
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
                  image = "lscr.io/linuxserver/speedtest-tracker:1.15.0";
                  publishPorts = [ "127.0.0.1:${toString my.port}:80" ];
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
      };
  };
}
