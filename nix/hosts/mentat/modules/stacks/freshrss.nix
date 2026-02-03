{ config, pkgs, ... }:
let
  stackPath = "/etc/stacks/freshrss";
  my = config.services.my.freshrss;

  youlag = pkgs.fetchFromGitHub {
    owner = "civilblur";
    repo = "youlag";
    rev = "v4.1.1";
    hash = "sha256-h0LN56NnbWiHUBbBLXvCV0cB1lJkpl1v6QL+U3qWQ+M=";
  };

  reddit = pkgs.fetchFromGitHub {
    owner = "aledeg";
    repo = "xExtension-RedditImage";
    rev = "v1.2.0";
    hash = "sha256-H/uxt441ygLL0RoUdtTn9Q6Q/Ois8RHlhF8eLpTza4Q=";
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  services.my.freshrss = {
    port = 3015;
    domain = "freshrss.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
    };
  };

  virtualisation.quadlet = {
    containers = {
      freshrss = {
        containerConfig = {
          image = "freshrss/freshrss:1.28.1";
          publishPorts = [ "127.0.0.1:${toString my.port}:80" ];
          volumes = [
            "${stackPath}/data:/var/www/FreshRSS/data"
            "${youlag}:/var/www/FreshRSS/extensions/xExtension-Youlag:ro"
            "${reddit}:/var/www/FreshRSS/extensions/xExtension-RedditImage:ro"
          ];
          environments = {
            TZ = "Europe/Berlin";
            CRON_MIN = "1,31";
          };
        };
        serviceConfig = {
          Restart = "on-failure";
        };
      };
    };
  };
}
