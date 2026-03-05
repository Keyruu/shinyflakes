{
  config,
  flake,
  lib,
  ...
}:
let
  inherit (flake.lib) quadlet;

  defaultMode = stackCfg: if stackCfg.user.enable then "0750" else "0755";
  defaultOwner = stackCfg: if stackCfg.user.enable then stackCfg.user.name else "root";
  defaultGroup = stackCfg: if stackCfg.user.enable then stackCfg.user.group else "root";

  normalizeDir =
    stackCfg: entry:
    let
      fallback = field: val: if val == null then field stackCfg else val;
    in
    if builtins.isString entry then
      {
        path = entry;
        mode = defaultMode stackCfg;
        owner = defaultOwner stackCfg;
        group = defaultGroup stackCfg;
      }
    else
      {
        inherit (entry) path;
        mode = fallback defaultMode entry.mode;
        owner = fallback defaultOwner entry.owner;
        group = fallback defaultGroup entry.group;
      };

  enabledStacks = lib.filterAttrs (_: svc: svc.stack.enable) config.services.my;

  resolve = override: global: if override != null then override else global;

  applySecurityDefaults =
    secCfg: containerName:
    let
      override = secCfg.overrides.${containerName} or { };
      effective = {
        dropAllCapabilities = resolve (override.dropAllCapabilities or null) secCfg.dropAllCapabilities;
        noNewPrivileges = resolve (override.noNewPrivileges or null) secCfg.noNewPrivileges;
        readOnlyRootFilesystem = resolve (override.readOnlyRootFilesystem or null
        ) secCfg.readOnlyRootFilesystem;
        memoryLimit = resolve (override.memoryLimit or null) secCfg.memoryLimit;
        pidsLimit = resolve (override.pidsLimit or null) secCfg.pidsLimit;
      };
    in
    {
      containerConfig =
        lib.optionalAttrs effective.dropAllCapabilities { dropCapabilities = lib.mkDefault [ "ALL" ]; }
        // lib.optionalAttrs effective.noNewPrivileges { noNewPrivileges = lib.mkDefault true; }
        // lib.optionalAttrs effective.readOnlyRootFilesystem { readOnly = lib.mkDefault true; }
        // lib.optionalAttrs (effective.memoryLimit != null) {
          memory = lib.mkDefault effective.memoryLimit;
        }
        // lib.optionalAttrs (effective.pidsLimit != null) {
          pidsLimit = lib.mkDefault effective.pidsLimit;
        };
    };
in
{
  options.services.my = lib.mkOption {
    type =
      with lib.types;
      attrsOf (
        submodule (
          { name, ... }:
          {
            options.stack = {
              enable = lib.mkEnableOption "stack infrastructure (directories, users, network)";

              path = lib.mkOption {
                type = lib.types.str;
                default = "/etc/stacks/${name}";
                description = "Base path for the stack's data. Exposed as a convenience attribute.";
              };

              directories = lib.mkOption {
                type =
                  with lib.types;
                  listOf (
                    either str (submodule {
                      options = {
                        path = lib.mkOption {
                          type = str;
                          description = "Subdirectory name under the stack path.";
                        };
                        mode = lib.mkOption {
                          type = nullOr str;
                          default = null;
                          description = "Permission mode for the directory. null = use stack default (0750 with user, 0755 without).";
                        };
                        owner = lib.mkOption {
                          type = nullOr str;
                          default = null;
                          description = "Owner of the directory. null = use stack default (user name or root).";
                        };
                        group = lib.mkOption {
                          type = nullOr str;
                          default = null;
                          description = "Group of the directory. null = use stack default (user group or root).";
                        };
                      };
                    })
                  );
                default = [ ];
                description = ''
                  Subdirectories to create under the stack path.
                  Each entry can be a string (creates subdir with defaults) or an attrset
                  with { path, mode, owner, group } for custom ownership/permissions.
                  When stack.user is enabled, directories default to being owned by that user.
                '';
                example = [
                  "data"
                  "config"
                  {
                    path = "db";
                    mode = "0770";
                    owner = "root";
                    group = "root";
                  }
                ];
              };

              user = {
                enable = lib.mkEnableOption "create a system user and group for this stack";

                name = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = "Username for the stack's system user.";
                };

                uid = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                  description = "Explicit UID for the user. null = auto-assigned.";
                };

                group = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = "Group name for the stack's system group.";
                };

                gid = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                  description = "Explicit GID for the group. null = auto-assigned.";
                };

                extraGroups = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Additional groups for the user.";
                  example = [ "syncthing" ];
                };
              };

              network = {
                enable = lib.mkEnableOption "create a dedicated bridge network for this stack";

                name = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = "Network name (also used as interface name).";
                };
              };

              containers = {
                members = lib.mkOption {
                  type = lib.types.listOf lib.types.anything;
                  default = [ ];
                  description = ''
                    Quadlet containers belonging to this stack.
                    Pass container values directly (e.g. containers.karakeep-web).
                    Used to auto-wire backup, network, and security.
                  '';
                };

                main = lib.mkOption {
                  type = lib.types.nullOr lib.types.anything;
                  default = null;
                  description = ''
                    The main container that serves the stack's port.
                    When set, auto-publishes my.port to this container's first
                    networkAlias port. Requires internalPort to be set.
                  '';
                };

                internalPort = lib.mkOption {
                  type = lib.types.nullOr lib.types.port;
                  default = null;
                  description = ''
                    The container-internal port of the main container.
                    Used with containers.main to auto-publish
                    127.0.0.1:<my.port>:<internalPort>.
                  '';
                };

                security = {
                  enable = lib.mkEnableOption "OWASP Docker security hardening for member containers";

                  dropAllCapabilities = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = ''
                      OWASP Rule #3: Drop all Linux capabilities by default.
                      Containers that need specific capabilities should add them
                      back via their own containerConfig.addCapabilities.
                    '';
                  };

                  noNewPrivileges = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = ''
                      OWASP Rule #4: Prevent in-container privilege escalation
                      via setuid/setgid binaries.
                    '';
                  };

                  readOnlyRootFilesystem = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = ''
                      OWASP Rule #8: Set container root filesystem to read-only.
                      All writes should go through explicit volumes or tmpfses.
                    '';
                  };

                  memoryLimit = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = ''
                      OWASP Rule #7: Limit container memory. null = no limit.
                    '';
                    example = "2g";
                  };

                  pidsLimit = lib.mkOption {
                    type = lib.types.nullOr lib.types.int;
                    default = null;
                    description = ''
                      OWASP Rule #7: Limit number of processes in the container. null = no limit.
                    '';
                    example = 200;
                  };

                  overrides = lib.mkOption {
                    type = lib.types.attrsOf (
                      lib.types.submodule {
                        options = {
                          dropAllCapabilities = lib.mkOption {
                            type = lib.types.nullOr lib.types.bool;
                            default = null;
                            description = "Override dropAllCapabilities for this container. null = use global.";
                          };
                          noNewPrivileges = lib.mkOption {
                            type = lib.types.nullOr lib.types.bool;
                            default = null;
                            description = "Override noNewPrivileges for this container. null = use global.";
                          };
                          readOnlyRootFilesystem = lib.mkOption {
                            type = lib.types.nullOr lib.types.bool;
                            default = null;
                            description = "Override readOnlyRootFilesystem for this container. null = use global.";
                          };
                          memoryLimit = lib.mkOption {
                            type = lib.types.nullOr lib.types.str;
                            default = null;
                            description = "Override memoryLimit for this container. null = use global.";
                          };
                          pidsLimit = lib.mkOption {
                            type = lib.types.nullOr lib.types.int;
                            default = null;
                            description = "Override pidsLimit for this container. null = use global.";
                          };
                        };
                      }
                    );
                    default = { };
                    description = ''
                      Per-container security overrides, keyed by container name.
                      Each option defaults to null (use global setting).
                      Set to a non-null value to override for that container.
                    '';
                    example = {
                      "karakeep-meilisearch" = {
                        readOnlyRootFilesystem = false;
                      };
                    };
                  };
                };
              };
            };
          }
        )
      );
  };

  config = lib.mkMerge [
    {
      systemd.tmpfiles.rules = lib.mkMerge (
        lib.mapAttrsToList (
          _name: svc:
          let
            stackCfg = svc.stack;
            dirs = map (normalizeDir stackCfg) stackCfg.directories;
          in
          lib.mkIf stackCfg.enable (
            map (dir: "d ${stackCfg.path}/${dir.path} ${dir.mode} ${dir.owner} ${dir.group}") dirs
          )
        ) enabledStacks
      );
    }

    {
      users = lib.mkMerge (
        lib.mapAttrsToList (
          _name: svc:
          let
            stackCfg = svc.stack;
            userCfg = stackCfg.user;
          in
          lib.mkIf (stackCfg.enable && userCfg.enable) {
            users.${userCfg.name} = {
              isSystemUser = true;
              inherit (userCfg) group extraGroups;
            }
            // lib.optionalAttrs (userCfg.uid != null) { inherit (userCfg) uid; };

            groups.${userCfg.group} = { } // lib.optionalAttrs (userCfg.gid != null) { inherit (userCfg) gid; };
          }
        ) enabledStacks
      );
    }

    {
      virtualisation.quadlet.networks = lib.mkMerge (
        lib.mapAttrsToList (
          _name: svc:
          let
            stackCfg = svc.stack;
            netCfg = stackCfg.network;
          in
          lib.mkIf (stackCfg.enable && netCfg.enable) {
            ${netCfg.name}.networkConfig = {
              driver = "bridge";
              interfaceName = netCfg.name;
            };
          }
        ) enabledStacks
      );
    }

    {
      virtualisation.quadlet.containers = lib.mkMerge (
        lib.concatLists (
          lib.mapAttrsToList (
            _name: svc:
            let
              stackCfg = svc.stack;
              netCfg = stackCfg.network;
              networkRef = config.virtualisation.quadlet.networks.${netCfg.name}.ref;
            in
            lib.optionals (stackCfg.enable && netCfg.enable && stackCfg.containers.members != [ ]) (
              map (container: {
                ${quadlet.name container}.containerConfig.networks = lib.mkDefault [ networkRef ];
              }) stackCfg.containers.members
            )
          ) enabledStacks
        )
      );
    }

    {
      virtualisation.quadlet.containers = lib.mkMerge (
        lib.mapAttrsToList (
          _name: svc:
          let
            stackCfg = svc.stack;
            containersCfg = stackCfg.containers;
            mainName = quadlet.name containersCfg.main;
          in
          lib.mkIf (stackCfg.enable && containersCfg.main != null && containersCfg.internalPort != null) {
            ${mainName}.containerConfig.publishPorts = lib.mkDefault [
              "127.0.0.1:${toString svc.port}:${toString containersCfg.internalPort}"
            ];
          }
        ) enabledStacks
      );
    }

    {
      services.my = lib.mkMerge (
        lib.mapAttrsToList (
          name: svc:
          let
            stackCfg = svc.stack;
            memberServices = map quadlet.service stackCfg.containers.members;
          in
          lib.mkIf (stackCfg.enable && svc.backup.enable) {
            ${name}.backup = {
              paths = lib.mkDefault [ stackCfg.path ];
            }
            // lib.optionalAttrs (stackCfg.containers.members != [ ]) {
              systemd.unit = lib.mkDefault memberServices;
            };
          }
        ) enabledStacks
      );
    }

    {
      virtualisation.quadlet.containers = lib.mkMerge (
        lib.concatLists (
          lib.mapAttrsToList (
            _name: svc:
            let
              stackCfg = svc.stack;
              secCfg = stackCfg.containers.security;
            in
            lib.optionals (stackCfg.enable && secCfg.enable) (
              map (
                container:
                let
                  name = quadlet.name container;
                in
                {
                  ${name} = applySecurityDefaults secCfg name;
                }
              ) stackCfg.containers.members
            )
          ) enabledStacks
        )
      );
    }
  ];
}
