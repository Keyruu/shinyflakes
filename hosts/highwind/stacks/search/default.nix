{config, ...}: let
  searxngPath = "/etc/stacks/searxng";
in {
  systemd.tmpfiles.rules = [
    "d ${searxngPath}/valkey 0775 root root"
    "d ${searxngPath}/data 0755 root root"
  ];

  sops.secrets = {
    searxngGluetunEnv.owner = "root";
    searxngEnv.owner = "root";
  };

  environment.etc."stacks/searxng/data/settings.yml" = {
    source = ./settings.yml;
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) containers;
  in { 
    containers = {
      "02-gluetun" = {
        containerConfig = {
          image = "ghcr.io/qdm12/gluetun:v3.40.0";
          addCapabilities = ["NET_ADMIN"];
          devices = ["/dev/net/tun:/dev/net/tun"];
          environmentFiles = [ config.sops.secrets.searxngGluetunEnv.path ];
          publishPorts = [
            "127.0.0.1:4899:8080"
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
            "${searxngPath}/valkey:/data"
          ];
          networks = [ containers."02-gluetun".ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
        unitConfig = {
          After = "02-gluetun.service";
          Requires = "02-gluetun.service";
        };
      };

      searxng-server = {
        containerConfig = {
          image = "docker.io/searxng/searxng:2025.1.26-70f1b6500";
          environments = {
            SEARXNG_BASE_URL = "https://search.lab.keyruu.de";
            UWSGI_WORKERS = "4";
            UWSGI_THREADS= "4";
            SEARXNG_REDIS_URL = "redis://localhost:6379/0";
          };
          environmentFiles = [ config.sops.secrets.searxngEnv.path ];
          volumes = [
            "${searxngPath}/data/settings.yml:/etc/searxng/settings.yml:ro"
          ];
          networks = [ containers."02-gluetun".ref ];
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
