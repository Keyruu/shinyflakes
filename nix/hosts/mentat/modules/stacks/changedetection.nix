{ config, flake, ... }:
let
  my = config.services.my.changedetection;
in
{
  imports = [ flake.modules.private.link-bypass ];

  services.link-bypass.enable = true;

  services.my.changedetection = {
    port = 5000;
    domain = "changedetection.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      user = {
        enable = true;
        name = "changedetection";
        uid = 1007;
        group = "changedetection";
        gid = 1007;
      };
      directories = [ "data" ];
      network.enable = true;
      security.enable = true;

      containers = {
        main = {
          containerConfig = {
            image = "ghcr.io/dgtlmoon/changedetection.io:0.54.8";
            publishPorts = [ "127.0.0.1:${toString my.port}:5000" ];
            volumes = [
              "${my.stack.path}/data:/datastore"
            ];
            user = "${toString my.stack.user.uid}:${toString my.stack.user.gid}";
            environments = {
              TZ = "Europe/Berlin";
              BASE_URL = "https://${my.domain}";
              PLAYWRIGHT_DRIVER_URL = "ws://browser:3000";
            };
            networkAliases = [ "changedetection" ];
          };
          dependsOn = [ "browser" ];
        };

        browser = {
          containerConfig = {
            image = "docker.io/dgtlmoon/sockpuppetbrowser:0.0.3";
            environments = {
              SCREEN_WIDTH = "1920";
              SCREEN_HEIGHT = "1024";
              SCREEN_DEPTH = "16";
              MAX_CONCURRENT_CHROME_PROCESSES = "10";
              CHROME_EXTRA_ARGS = "--no-sandbox";
            };
            networkAliases = [ "browser" ];
          };
        };
      };
    };
  };
}
