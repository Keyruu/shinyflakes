{ ... }:
{
  den.aspects.services.media.silo = {
    nixos =
      {
        config,
        pkgs,
        ...
      }:
      let
        my = config.services.my.silo;
        domain = "silo.port.peeraten.net";

        # Provisioning document: Silo installs and configures the official OIDC
        # plugin from this file on start, so sign-in needs no admin UI clicks.
        # https://siloserver.org/docs/provision-plugins
        pluginsFile = (pkgs.formats.json { }).generate "silo-plugins.json" {
          apiVersion = 1;
          plugins."silo.auth.oidc" = {
            version = "0.1.2";
            config = {
              connection = {
                issuer_url = "https://auth.peeraten.net";
                client_id = "silo";
                client_secret.fromFile = "/run/secrets/silo-client-secret";
                request_groups_scope = true;
              };
              # the plugin's manifest schema types these as strings (one group
              # per line); an array is refused by provisioning validation
              access = {
                allowed_groups = "silo_users";
                admin_groups = "admin";
              };
            };
            auth_binding = {
              capability_id = "oidc";
              enabled = true;
              auto_provision = true;
              # stable callback: no plugin installation id in the URL
              callback = "stable";
            };
          };
        };
      in
      {
        sops.secrets = {
          siloSecretKey = { };
          # silo reads this inside the container as PUID 1026
          siloClientSecret = {
            owner = "silo";
            group = "users";
            mode = "0400";
          };
        };

        sops.templates."silo.env" = {
          restartUnits = [ "silo.service" ];
          content = ''
            SECRET_KEY=${config.sops.placeholder.siloSecretKey}
          '';
        };

        services.my.silo = {
          zfs = true;
          port = 8090;
          inherit domain;
          title = "Silo";
          dashboard = {
            groups = [ "silo_users" ];
            # dashboard-icons has no silo entry
            icon = "https://siloserver.org/web-app-icon-512.png";
          };
          monitor.healthPath = "/api/v1/ready";
          oidc = {
            enable = true;
            # pbkdf2 hash of sops.siloClientSecret
            clientSecret = "$pbkdf2-sha512$310000$9X2cX7LlT4VjRgQ5KT0SCg$IneanajdKvxYTKhwoKh..BmekgF9qNz0HBd0UDJSvsKdsZgDrGQjCmYVKDwVuXZmFhipwXt30vHNJwmhNX3GhQ";
            redirectUris = [ "https://${domain}/api/v2/auth/oauth/callback" ];
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            # the plugin sends PKCE S256 on every sign-in
            requirePkce = true;
          };
          proxy = {
            enable = true;
            cert = {
              provided = false;
              host = "port.peeraten.net";
            };
          };
          backup.enable = true;
          stack = {
            enable = true;
            # media files are not world-readable, so join the host's `users` group
            user = {
              enable = true;
              uid = 1026;
              group = "users";
              gid = 100;
            };
            directories = [
              "config"
              "transcode"
              "download-artifacts"
            ];
            security.enable = false;

            containers.silo = {
              containerConfig = {
                image = "ghcr.io/silo-server/silo-server:build-2624";
                # needs NET_ADMIN for its TCP tuning of remote viewer connections
                addCapabilities = [ "NET_ADMIN" ];
                # bundled postgres needs time to shut down; podman kills after 10s
                stopTimeout = 120;
                # AMD Renoir iGPU for VAAPI transcoding
                devices = [ "/dev/dri:/dev/dri" ];
                environments = {
                  PUID = "1026";
                  PGID = "100";
                  TZ = "Europe/Berlin";
                  SILO_PUBLIC_URL = "https://${domain}";
                  SILO_PLUGINS_FILE = "/run/silo-provisioning/plugins.json";
                  # mentat's nginx is the only ingress. Published ports reach the
                  # container from the podman network gateway, not 127.0.0.1, so
                  # without this silo ignores X-Forwarded-Proto and sees every
                  # app sign-in as http:// instead of the https public URL.
                  SILO_TRUSTED_PROXIES = "10.88.0.1/32";
                  SILO_HW_ACCEL = "vaapi";
                  # jellyfin keeps 8096; the compat listener stays off
                  SILO_JELLYFIN_ENABLED = "false";
                };
                environmentFiles = [ config.sops.templates."silo.env".path ];
                volumes = [
                  "${my.stack.path}/config:/config"
                  "${my.stack.path}/transcode:/tmp/silo-transcode"
                  "${my.stack.path}/download-artifacts:/tmp/silo-download-artifacts"
                  "/main/media:/mnt/media:ro"
                  "${pluginsFile}:/run/silo-provisioning/plugins.json:ro"
                  "${config.sops.secrets.siloClientSecret.path}:/run/secrets/silo-client-secret:ro"
                ];
                publishPorts = [ "127.0.0.1:${toString my.port}:8080" ];
              };
              # systemd's 90s DefaultTimeoutStopSec would cut the 120s stop timeout short
              serviceConfig.TimeoutStopSec = 120;
            };
          };
        };
      };
  };
}
