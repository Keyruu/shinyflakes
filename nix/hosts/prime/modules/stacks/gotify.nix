{ config, flake, ... }:
let
  my = config.services.my.gotify;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets.gotifyDefaultPassword = { };

  sops.templates."gotify.env" = {
    restartUnits = [ (quadlet.service containers.gotify) ];
    content = ''
      GOTIFY_DEFAULTUSER_PASS=${config.sops.placeholder.gotifyDefaultPassword}
    '';
  };

  services = {
    my.gotify = {
      port = 8080;
      domain = "notify.keyruu.de";
      proxy.enable = false;
      backup.enable = true;
      stack = {
        enable = true;
        directories = [ "data" ];
        security.enable = true;

        containers.gotify = {
          containerConfig = {
            image = "gotify/server:2.9.1";
            publishPorts = [ "127.0.0.1:${toString my.port}:8080" ];
            volumes = [ "${my.stack.path}/data:/app/data" ];
            environmentFiles = [ config.sops.templates."gotify.env".path ];
            environments = {
              GOTIFY_SERVER_PORT = "8080";
            };
          };
        };
      };
    };
    caddy.virtualHosts."notify.keyruu.de" = {
      extraConfig = ''
        @websockets {
          path /stream
        }
        handle @websockets {
          reverse_proxy 127.0.0.1:${toString my.port} {
            header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
          }
        }

        handle {
          route {
            coraza_waf {
              load_owasp_crs
              directives `
                SecRuleEngine On
                Include @coraza.conf-recommended
                Include @crs-setup.conf.example
                Include @owasp_crs/*.conf

                # remove REQUEST-949-BLOCKING-EVALUATION bc of a lot of false positives
                SecRuleRemoveById 949110
                # somehow this blocks some http protocol, idfk 
                SecRuleRemoveById 920420
              `
            }
            reverse_proxy 127.0.0.1:${toString my.port}
          }
        }
      '';
    };
  };
}
