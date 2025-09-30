{ config, ... }:
let
  searxngPath = "/etc/stacks/searxng";
in
{
  systemd.tmpfiles.rules = [
    "d ${searxngPath}/valkey 0775 999 1000"
    "d ${searxngPath}/data 0755 root root"
  ];

  sops.secrets = {
    searxngGluetunEnv.owner = "root";
    searxngEnv.owner = "root";
  };

  environment.etc."stacks/searxng/data/settings.yml" = {
    source = ./settings.yml;
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) containers;
    in
    {
      containers = {
        "searxng-gluetun" = {
          containerConfig = {
            image = "ghcr.io/qdm12/gluetun:v3.40.0";
            addCapabilities = [ "NET_ADMIN" ];
            devices = [ "/dev/net/tun:/dev/net/tun" ];
            environmentFiles = [ config.sops.secrets.searxngGluetunEnv.path ];
            publishPorts = [
              "127.0.0.1:4899:8080"
            ];
            labels = [
              "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"
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
              "${searxngPath}/valkey:/data:z"
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
              "${searxngPath}/data/settings.yml:/etc/searxng/settings.yml:ro"
            ];
            networks = [ containers."searxng-gluetun".ref ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+-.*$"
            ];
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

  services.nginx.virtualHosts."search.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:4899";
      proxyWebsockets = true;
    };
  };
}
