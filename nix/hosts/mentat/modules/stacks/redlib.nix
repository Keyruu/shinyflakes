{ config, ... }:
let
  stackPath = "/etc/stacks/redlib";
in
{
  # 1. Sops secrets for redlib environment variables
  sops.secrets = {
    redlibConfig = {
      restartUnits = [ "redlib.service" ];
    };
  };

  # 2. Directory creation
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/config 0755 root root"
  ];

  # 3. Environment template for redlib
  sops.templates."redlib.env" = {
    restartUnits = [ "redlib.service" ];
    content = ''
      # Redlib Configuration
      REDLIB_CONFIG=${config.sops.placeholder.redlibConfig}

      # Optional settings (add as needed)
      # REDLIB_DEFAULT_TRENDING_SUB=all
      # REDLIB_DEFAULT_POST_SORT=hot
      # REDLIB_DEFAULT_SUB_SORT=hot
      # REDLIB_DEFAULT_SHOW_NSFW=on
      # REDLIB_DEFAULT_USE_HLS=on
      # REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION=on
    '';
  };

  # 4. Quadlet configuration for redlib
  virtualisation.quadlet = {
    containers = {
      redlib = {
        containerConfig = {
          image = "quay.io/redlib/redlib:latest";
          publishPorts = [ "127.0.0.1:8080:8080" ];
          user = "65534"; # nobody user
          volumes = [
            "${stackPath}/data:/data:ro"
          ];
          environmentFiles = [ config.sops.templates."redlib.env".path ];
          labels = [
            "wud.tag.include=^\d+\.\d+\.\d+$"
          ];

          # Security settings
          noNewPrivileges = true;
          readOnly = true;

          # Health check
          healthCmd = "wget --no-verbose --tries=1 --spider --quiet http://localhost:8080/settings";
          healthInterval = "5m";
          healthTimeout = "3s";
          healthRetries = 3;
          healthStartPeriod = "30s";
        };

        serviceConfig = {
          Restart = "always";
        };

        unitConfig = {
          Description = "Redlib - Privacy-focused Reddit frontend";
          Documentation = "https://github.com/redlib-org/redlib";
        };
      };
    };
  };

  # 5. ACME certificate for reverse proxy
  security.acme = {
    certs."redlib.lab.keyruu.de" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  # 6. Nginx reverse proxy configuration
  services.nginx.virtualHosts."redlib.lab.keyruu.de" = {
    useACMEHost = "redlib.lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      proxyWebsockets = true;
    };
  };
}
