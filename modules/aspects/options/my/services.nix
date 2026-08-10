{
  ...
}:
{
  den.aspects.options.my.services.nixos =
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

      # Allowlist for a service = IPs of people who have service-access for this service.
      # Used by nginx vhost when topology includes "internal".
      allowlistIps =
        name:
        let
          granted = lib.attrValues (
            lib.filterAttrs (_: p: builtins.elem name (p.service-access or [ ])) config.den.people
          );
          ips = lib.concatMap (p: lib.concatMap (_: d: [ d.ip ]) (lib.attrValues p.devices)) granted;
        in
        lib.concatMapStringsSep "\n" (ip: "allow ${ip};") ips;
    in
    {
      options.services.my = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                enable = lib.mkEnableOption "my service";
                description = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = "Human-readable description (shown on dashboard card, docs).";
                };
                zfs = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Whether this service depends on encrypted ZFS datasets. Wires up zfs-encrypted.target dependencies.";
                };
                port = lib.mkOption {
                  type = lib.types.nullOr lib.types.port;
                  default = null;
                };
                domain = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Public domain name (e.g. \"karakeep.lab.keyruu.de\"). null for internal-only services.";
                };
                topology = lib.mkOption {
                  type = lib.types.enum [
                    "internal"
                    "external"
                    "both"
                  ];
                  default = "external";
                  description = ''
                    Network topology this service is reachable from.
                      internal = LAN-only, IP allowlist from people.service-access
                      external = public via Cloudflare proxy, OIDC via authelia
                      both     = both layers apply
                  '';
                };
                proxy = lib.mkOption {
                  type = lib.types.submodule {
                    options = {
                      enable = lib.mkEnableOption "proxy";
                      server = lib.mkOption {
                        type = lib.types.enum [
                          "nginx"
                          "caddy"
                        ];
                        default = "nginx";
                      };
                      cloudflareOnly = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = "Reject traffic not originating from Cloudflare (caddy only).";
                      };
                      cert = lib.mkOption {
                        type = lib.types.submodule {
                          options = {
                            provided = lib.mkOption {
                              type = lib.types.bool;
                              default = true;
                            };
                            host = lib.mkOption {
                              type = lib.types.str;
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
                  type = lib.types.submodule {
                    options = {
                      enable = lib.mkEnableOption "enable backup";
                      paths = lib.mkOption { type = lib.types.listOf lib.types.str; };
                      systemd = lib.mkOption {
                        type = lib.types.submodule {
                          options = {
                            enable = lib.mkOption {
                              type = lib.types.bool;
                              default = true;
                            };
                            unit = lib.mkOption {
                              type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
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
        ]
        ++ lib.concatLists (
          lib.mapAttrsToList (name: cfg: [
            {
              assertion = cfg.proxy.enable -> cfg.port != null;
              message = "services.my.${name}: proxy.enable requires port to be set.";
            }
            {
              assertion = cfg.proxy.cloudflareOnly -> cfg.proxy.server == "caddy";
              message = "services.my.${name}: proxy.cloudflareOnly only applies to caddy.";
            }
          ]) config.services.my
        );
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
            name: serviceCfg:
            lib.mkIf (serviceCfg.proxy.enable && serviceCfg.proxy.server == "nginx" && serviceCfg.port != null)
              {
                ${serviceCfg.domain} = {
                  useACMEHost = serviceCfg.proxy.cert.host;
                  forceSSL = true;
                  locations."/" = {
                    proxyPass = "http://127.0.0.1:${toString serviceCfg.port}";
                    proxyWebsockets = true;
                    extraConfig = lib.mkIf (serviceCfg.topology == "internal" || serviceCfg.topology == "both") ''
                      ${allowlistIps name}
                      allow 192.168.100.0/24;
                      deny all;
                    '';
                  };
                };
              }
          ) config.services.my
        );

        services.caddy.virtualHosts = lib.mkMerge (
          lib.mapAttrsToList (
            _name: serviceCfg:
            lib.mkIf (serviceCfg.proxy.enable && serviceCfg.proxy.server == "caddy" && serviceCfg.port != null)
              {
                ${serviceCfg.domain} = {
                  extraConfig = ''
                    import coraza-waf
                    ${lib.optionalString serviceCfg.proxy.cloudflareOnly "import cloudflare-only"}
                    reverse_proxy http://127.0.0.1:${toString serviceCfg.port}
                  '';
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
    };
}
