{ lib, ... }:
{
  options.services.my = lib.mkOption {
    type =
      with lib.types;
      attrsOf (
        submodule (
          { config, ... }:
          {
            options = {
              enable = lib.mkEnableOption "my service";
              port = lib.mkOption { type = port; };
              domain = lib.mkOption { type = str; };
              # proxy = lib.mkEnableOption "proxy the service";
              proxy = lib.mkOption {
                type = submodule {
                  options = {
                    enable = lib.mkEnableOption "proxy";
                    # public = lib.mkOption {
                    #   type = bool;
                    #   default = false;
                    # };
                    cert = lib.mkOption {
                      type = submodule {
                        options = {
                          provided = lib.mkOption {
                            type = bool;
                            default = true;
                          };
                          host = lib.mkOption {
                            type = str;
                            default = "lab.keyruu.de";
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
            config = lib.mkMerge [
              (lib.mkIf (config.cert.host != null && !config.proxy.cert.provided) {
                security.acme.certs.${config.cert.host} = {
                  dnsProvider = "cloudflare";
                  dnsPropagationCheck = true;
                  environmentFile = config.sops.secrets.cloudflare.path;
                };
              })

              (lib.mkIf (config.proxy.enable or false && config.domain != null) {
                services.nginx.virtualHosts.${config.domain} = {
                  useACMEHost = config.cert.host;
                  forceSSL = true;
                  locations."/" = {
                    proxyPass = "http://127.0.0.1:${toString config.port}";
                    proxyWebsockets = true;
                  };
                };
              })
            ];
          }
        )
      );
    default = { };
  };
}
