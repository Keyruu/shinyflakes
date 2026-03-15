{ config, perSystem, ... }:
let
  my = config.services.my.freshrss;
in
{
  services.my.freshrss = {
    port = 3015;
    domain = "freshrss.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = false;

      containers = {
        freshrss = {
          containerConfig = {
            image = "freshrss/freshrss:1.28.1";
            publishPorts = [ "127.0.0.1:${toString my.port}:80" ];
            volumes = [
              "${my.stack.path}/data:/var/www/FreshRSS/data"
              "${perSystem.self.freshrss-youlag}:/var/www/FreshRSS/extensions/xExtension-Youlag:ro"
              "${perSystem.self.freshrss-reddit}:/var/www/FreshRSS/extensions/xExtension-RedditImage:ro"
            ];
            environments = {
              TZ = "Europe/Berlin";
              CRON_MIN = "1,31";
            };
          };
        };
      };
    };
  };
}
