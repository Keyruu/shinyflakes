{ config, ... }:
let
  my = config.services.my.searxng;
  inherit (config.virtualisation.quadlet) containers;
in
{
  sops.secrets = {
    searxngGluetunEnv.owner = "root";
    searxngEnv.owner = "root";
  };

  environment.etc."stacks/searxng/data/settings.yml" = {
    source = ./settings.yml;
  };

  services.my.searxng = {
    port = 4899;
    domain = "search.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        {
          path = "valkey";
          mode = "0775";
          owner = "999";
          group = "1000";
        }
        "data"
      ];
      security.enable = false;

      containers = {
        gluetun = {
          containerConfig = {
            image = "ghcr.io/qdm12/gluetun:v3.41.1";
            addCapabilities = [ "NET_ADMIN" ];
            devices = [ "/dev/net/tun:/dev/net/tun" ];
            environmentFiles = [ config.sops.secrets.searxngGluetunEnv.path ];
          };
        };

        redis = {
          containerConfig = {
            image = "docker.io/valkey/valkey:8-alpine";
            exec = "valkey-server --save 30 1 --loglevel warning";
            volumes = [
              "${my.stack.path}/valkey:/data:z"
            ];
            networks = [ containers.searxng-gluetun.ref ];
          };
          dependsOn = [ "gluetun" ];
        };

        server = {
          containerConfig = {
            image = "docker.io/searxng/searxng:2025.9.12-d79ad74";
            publishPorts = [ "127.0.0.1:${toString my.port}:8080" ];
            environments = {
              SEARXNG_BASE_URL = "https://search.lab.keyruu.de";
              UWSGI_WORKERS = "4";
              UWSGI_THREADS = "4";
              SEARXNG_REDIS_URL = "redis://localhost:6379/0";
            };
            environmentFiles = [ config.sops.secrets.searxngEnv.path ];
            volumes = [
              "${my.stack.path}/data/settings.yml:/etc/searxng/settings.yml:ro"
            ];
            networks = [ containers.searxng-gluetun.ref ];
          };
          dependsOn = [ "redis" ];
          unitConfig = {
            X-RestartTrigger = [
              "${config.environment.etc."stacks/searxng/data/settings.yml".source}"
            ];
          };
        };
      };
    };
  };
}
