{
  config,
  lib,
  pkgs,
  ...
}:
let
  servicesWithPorts = lib.filterAttrs (_: svc: svc.port != null) config.services.my;
  portList = lib.mapAttrsToList (name: svc: {
    inherit name;
    inherit (svc) port;
  }) servicesWithPorts;

  groupedByPort = lib.groupBy (svc: toString svc.port) portList;
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
      attrsOf (
        submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "my service";
              port = lib.mkOption {
                type = lib.types.nullOr lib.types.port;
                default = null;
              };
              domain = lib.mkOption { type = str; };
              proxy = lib.mkOption {
                type = submodule {
                  options = {
                    enable = lib.mkEnableOption "proxy";
                    # public = lib.mkEnableOption "will this be proxied by a vps";
                    whitelist = lib.mkOption {
                      type = submodule {
                        options = {
                          enable = lib.mkEnableOption "restrict the proxy to specific people";
                          people = lib.mkOption {
                            type = listOf str;
                            default = [ ];
                          };
                        };
                      };
                      default = { };
                    };
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
                default = { };
              };
              backup = lib.mkOption {
                type = submodule {
                  options = {
                    enable = lib.mkEnableOption "enable backup";
                    paths = lib.mkOption { type = listOf str; };
                    systemd = lib.mkOption {
                      type = submodule {
                        options = {
                          enable = lib.mkOption {
                            type = bool;
                            default = true;
                          };
                          unit = lib.mkOption {
                            type = either str (listOf str);
                            default = name;
                          };
                        };
                      };
                      default = { };
                    };
                  };
                };
                default = { };
              };
            };
          }
        )
      );
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
        lib.mkIf (serviceCfg.proxy.enable && serviceCfg.port != null) {
          ${serviceCfg.domain} = {
            useACMEHost = serviceCfg.proxy.cert.host;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString serviceCfg.port}";
              proxyWebsockets = true;
              extraConfig = lib.mkIf serviceCfg.proxy.whitelist.enable ''
                ${lib.pipe config.services.mesh.people [
                  (lib.filterAttrs (person: _: builtins.elem person serviceCfg.proxy.whitelist.people))
                  (lib.mapAttrsToList (
                    _: person: lib.mapAttrsToList (_: device: "allow ${device.ip};") person.devices
                  ))
                  lib.flatten
                  (lib.concatStringsSep "\n")
                ]}

                allow 192.168.100.0/24;
                deny all;
              '';
            };
          };
        }
      ) config.services.my
    );

    services.restic.backupsWithDefaults = lib.mkMerge (
      lib.mapAttrsToList (
        name: cfg:
        let
          unitStr =
            if builtins.isList cfg.backup.systemd.unit then
              lib.concatStringsSep " " cfg.backup.systemd.unit
            else
              cfg.backup.systemd.unit;
        in
        lib.mkIf cfg.backup.enable {
          ${name} = {
            inherit (cfg.backup) paths;
            backupPrepareCommand = lib.optionalString cfg.backup.systemd.enable "${pkgs.systemd}/bin/systemctl stop ${unitStr}";
            backupCleanupCommand = lib.optionalString cfg.backup.systemd.enable "${pkgs.systemd}/bin/systemctl start ${unitStr}";
          };
        }
      ) config.services.my
    );
  };
}
