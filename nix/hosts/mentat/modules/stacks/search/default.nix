{ config, ... }:
let
  stackPath = "/etc/stacks/searxng";
  my = config.services.my.searxng;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/valkey 0775 999 1000"
    "d ${stackPath}/data 0755 root root"
  ];

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
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit = "searxng-*";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) containers;
    in
    {
      containers = {
        "searxng-gluetun" = {
          containerConfig = {
            image = "ghcr.io/qdm12/gluetun:v3.41.1";
            addCapabilities = [ "NET_ADMIN" ];
            devices = [ "/dev/net/tun:/dev/net/tun" ];
            environmentFiles = [ config.sops.secrets.searxngGluetunEnv.path ];
            publishPorts = [
              "127.0.0.1:${toString my.port}:8080"
            ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        searxng-redis = {
          containerConfig = {
            image = "docker.io/valkey/valkey:8-alpine";
            exec = "valkey-server --save 30 1 --loglevel warning";
            volumes = [
              "${stackPath}/valkey:/data:z"
            ];
            networks = [ containers."searxng-gluetun".ref ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = "searxng-gluetun.service";
            Requires = "searxng-gluetun.service";
          };
        };

        searxng-server = {
          containerConfig = {
            image = "docker.io/searxng/searxng:2025.9.12-d79ad74";
            environments = {
              SEARXNG_BASE_URL = "https://search.lab.keyruu.de";
              UWSGI_WORKERS = "4";
              UWSGI_THREADS = "4";
              SEARXNG_REDIS_URL = "redis://localhost:6379/0";
            };
            environmentFiles = [ config.sops.secrets.searxngEnv.path ];
            volumes = [
              "${stackPath}/data/settings.yml:/etc/searxng/settings.yml:ro"
            ];
            networks = [ containers."searxng-gluetun".ref ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [
              "searxng-redis.service"
            ];
            Requires = [
              "searxng-redis.service"
            ];
            X-RestartTrigger = [
              "${config.environment.etc."stacks/searxng/data/settings.yml".source}"
            ];
          };
        };
      };
    };
}
