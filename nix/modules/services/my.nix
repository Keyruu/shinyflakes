{ config, lib, ... }:
let
  servicesWithPorts = lib.mapAttrsToList (name: svc: {
    inherit name;
    inherit (svc) port;
  }) config.services.my;

  groupedByPort = lib.groupBy (svc: toString svc.port) servicesWithPorts;
  duplicatePorts = lib.filterAttrs (_port: services: builtins.length services > 1) groupedByPort;

  formatDuplicates = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      port: services: "  Port ${port}: ${lib.concatMapStringsSep ", " (s: s.name) services}"
    ) duplicatePorts
  );
in
{
  options.services.my = lib.mkOption {
    type =
      with lib.types;
      attrsOf (submodule {
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
                  default = { };
                };
              };
            };
          };
        };
      });
    default = { };
  };

  config = {
    assertions = [
      {
        assertion = duplicatePorts == { };
        message = ''
          Duplicate ports found in services.my configuration!
          The following ports are used by multiple services:
          ${formatDuplicates}
        '';
      }
    ];

    security.acme.certs = lib.mkMerge (
      lib.mapAttrsToList (
        _name: serviceCfg:
        lib.mkIf (serviceCfg.proxy.enable && !serviceCfg.proxy.cert.provided) {
          ${serviceCfg.proxy.cert.host} = {
            dnsProvider = "cloudflare";
            dnsPropagationCheck = true;
            environmentFile = config.sops.secrets.cloudflare.path;
          };
        }
      ) config.services.my
    );

    services.nginx.virtualHosts = lib.mkMerge (
      lib.mapAttrsToList (
        _name: serviceCfg:
        lib.mkIf serviceCfg.proxy.enable {
          ${serviceCfg.domain} = {
            useACMEHost = serviceCfg.proxy.cert.host;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString serviceCfg.port}";
              proxyWebsockets = true;
            };
          };
        }
      ) config.services.my
    );
  };
}
