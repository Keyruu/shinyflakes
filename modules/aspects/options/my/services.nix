{
  den,
  ...
}:
{
  den.aspects.options.my.services =
    let
      hostIp = host: host.mesh.ip or null;
    in
    {
      nixos =
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
          allowlistIps =
            name:
            let
              granted = lib.attrValues (
                lib.filterAttrs (_: p: builtins.elem name (p.service-access or [ ])) den.people
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
                    origins = lib.mkOption {
                      type = lib.types.nullOr (lib.types.listOf lib.types.str);
                      default = null;
                      description = ''
                        WebService Origins strings, joined with spaces and
                        written to `services.<name>.settings.WebService.Origins`.
                        Each entry is one origin the service should accept
                        (e.g. `"https://x.example"` or `"ws://x.example"`).

                        When `null`, consumers may derive their own default
                        from `domain` (e.g. cockpit defaults to https/wss
                        URLs built from `domain`). Set explicitly for
                        mesh-direct or other non-HTTPS deployments.
                      '';
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
                          whitelist = lib.mkOption {
                            type = lib.types.submodule {
                              options.enable = lib.mkOption {
                                type = lib.types.bool;
                                default = false;
                                description = "Restrict the nginx vhost to den.people with service-access for this service.";
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

                    # Per-service slices consumed via the `service` quirk.
                    dashboard = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          enable = lib.mkOption {
                            type = lib.types.bool;
                            default = true;
                          };
                          title = lib.mkOption {
                            type = lib.types.str;
                            default = name;
                          };
                          icon = lib.mkOption {
                            type = lib.types.str;
                            default = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/${name}.svg";
                          };
                          newTab = lib.mkOption {
                            type = lib.types.bool;
                            default = true;
                          };
                          groups = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            default = [
                              "admin"
                              "${name}_users"
                            ];
                          };
                        };
                      };
                      default = { };
                    };
                    monitor = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          enable = lib.mkOption {
                            type = lib.types.bool;
                            default = true;
                          };
                          url = lib.mkOption {
                            type = lib.types.nullOr lib.types.str;
                            default = null;
                            description = "Override full URL (else built from domain + healthPath).";
                          };
                          healthPath = lib.mkOption {
                            type = lib.types.str;
                            default = "/";
                          };
                          interval = lib.mkOption {
                            type = lib.types.str;
                            default = "30s";
                          };
                          conditions = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            default = [ "[STATUS] == 200" ];
                          };
                        };
                      };
                      default = { };
                    };
                    scrape = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          enable = lib.mkOption {
                            type = lib.types.bool;
                            default = false;
                          };
                          port = lib.mkOption {
                            type = lib.types.nullOr lib.types.port;
                            default = null;
                            description = "Override port (else service.port).";
                          };
                          metricsPath = lib.mkOption {
                            type = lib.types.str;
                            default = "/metrics";
                          };
                          interval = lib.mkOption {
                            type = lib.types.str;
                            default = "15s";
                          };
                        };
                      };
                      default = { };
                    };
                    oidc = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          enable = lib.mkOption {
                            type = lib.types.bool;
                            default = false;
                          };
                          clientId = lib.mkOption {
                            type = lib.types.str;
                            default = name;
                          };
                          redirectPath = lib.mkOption {
                            type = lib.types.str;
                            default = "";
                            description = "Path appended to https://\${domain} to form redirectUri.";
                          };
                          scopes = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            default = [
                              "openid"
                              "email"
                              "profile"
                            ];
                          };
                          tokenEndpointAuthMethod = lib.mkOption {
                            type = lib.types.enum [
                              "client_secret_basic"
                              "client_secret_post"
                              "none"
                            ];
                            default = "client_secret_post";
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
                {
                  assertion = cfg.dashboard.enable -> cfg.domain != null;
                  message = "services.my.${name}: dashboard.enable requires domain to be set.";
                }
                {
                  assertion = cfg.monitor.enable -> (cfg.domain != null || cfg.monitor.url != null);
                  message = "services.my.${name}: monitor.enable requires domain or monitor.url.";
                }
                {
                  assertion = cfg.scrape.enable -> (cfg.port != null || cfg.scrape.port != null);
                  message = "services.my.${name}: scrape.enable requires port or scrape.port.";
                }
                {
                  assertion = cfg.oidc.enable -> cfg.domain != null;
                  message = "services.my.${name}: oidc.enable requires domain.";
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

      # 5 quirk emitters — config thunks reading the host's services.my.
      # Each entry carries its own `enable` flag; pipes in services-collect.nix
      # filter out entries where enable is false. `hostIp` is the mesh IP of
      # this host, baked into every entry so cross-host consumers
      # (prometheus, public-proxy) can target the service without
      # re-deriving source context. null for LAN-only hosts.

      dashboard =
        {
          host,
          lib,
          config,
          ...
        }:
        lib.mapAttrsToList (
          name: svc:
          svc.dashboard
          // {
            inherit name;
            inherit (svc) description domain;
            hostIp = hostIp host;
            url = "https://${svc.domain}";
          }
        ) (lib.filterAttrs (_: svc: svc.dashboard.enable) config.services.my);

      monitor =
        {
          lib,
          config,
          host,
          ...
        }:
        lib.mapAttrsToList (
          name: svc:
          svc.monitor
          // {
            inherit name;
            inherit (svc) domain;
            hostIp = hostIp host;
            fullUrl =
              if svc.monitor.url != null then
                svc.monitor.url
              else
                "https://${svc.domain}${svc.monitor.healthPath}";
          }
        ) (lib.filterAttrs (_: svc: svc.monitor.enable) config.services.my);

      scrape =
        {
          lib,
          config,
          host,
          ...
        }:
        lib.mapAttrsToList (
          name: svc:
          svc.scrape
          // {
            inherit name;
            inherit (svc) port;
            hostIp = hostIp host;
            scrapePort = if svc.scrape.port != null then svc.scrape.port else svc.port;
          }
        ) (lib.filterAttrs (_: svc: svc.scrape.enable) config.services.my);

      public-proxy =
        {
          lib,
          config,
          host,
          ...
        }:
        lib.mapAttrsToList (
          name: svc:
          svc.proxy
          // {
            inherit name;
            inherit (svc) domain port;
            hostIp = hostIp host;
          }
        ) (lib.filterAttrs (_: svc: svc.proxy.enable) config.services.my);

      oidc-config =
        {
          lib,
          config,
          host,
          ...
        }:
        lib.mapAttrsToList (
          name: svc:
          svc.oidc
          // {
            inherit name;
            inherit (svc) domain;
            hostIp = hostIp host;
            redirectUri = "https://${svc.domain}${svc.oidc.redirectPath}";
          }
        ) (lib.filterAttrs (_: svc: svc.oidc.enable) config.services.my);
    };
}
