{ ... }:
{
  den.aspects.services.gotify = {
    nixos =
      { config, ... }:
      let
        my = config.services.my.gotify;
      in
      {
        sops.secrets = {
          gotifyDefaultPassword = { };
          gotifyClientSecret = { };
        };

        sops.templates."gotify.env" = {
          restartUnits = [ "gotify.service" ];
          content = ''
            GOTIFY_DEFAULTUSER_PASS=${config.sops.placeholder.gotifyDefaultPassword}
            GOTIFY_OIDC_CLIENTSECRET=${config.sops.placeholder.gotifyClientSecret}
          '';
        };

        services.my.gotify = {
          port = 8080;
          domain = "notify.keyruu.de";
          description = "Push notifications";
          dashboard = {
            enable = true;
            title = "Gotify";
            groups = [ "gotify_users" ];
          };
          proxy.enable = false;
          backup.enable = true;
          stack = {
            enable = true;
            directories = [ "data" ];
            security.enable = true;

            containers.gotify = {
              containerConfig = {
                image = "docker.io/gotify/server:3.0.0";
                publishPorts = [ "127.0.0.1:${toString my.port}:8080" ];
                volumes = [ "${my.stack.path}/data:/app/data" ];
                environmentFiles = [ config.sops.templates."gotify.env".path ];
                environments = {
                  GOTIFY_SERVER_PORT = "8080";
                  GOTIFY_OIDC_ENABLED = "true";
                  GOTIFY_OIDC_ISSUER = "https://auth.peeraten.net";
                  GOTIFY_OIDC_CLIENTID = "gotify";
                  GOTIFY_OIDC_REDIRECTURL = "https://${my.domain}/auth/oidc/callback";
                };
              };
            };
          };
        };

        services.caddy.virtualHosts."notify.keyruu.de" = {
          extraConfig = ''
            import websocket /stream 127.0.0.1:${toString my.port}

            handle {
              import coraza-waf
              reverse_proxy 127.0.0.1:${toString my.port}
            }
          '';
        };
      };
  };
}
