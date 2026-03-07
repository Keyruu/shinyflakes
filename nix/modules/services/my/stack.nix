{
  config,
  options,
  flake,
  lib,
  ...
}:
let

  # reuse the quadlet-nix container submodule via getSubModules so stack
  # containers share the same options as virtualisation.quadlet.containers.*.
  containerModules =
    options.virtualisation.quadlet.containers.type.nestedTypes.elemType.getSubModules;

  # each entry defines one security setting. stack-global options, per-container
  # overrides and the containerConfig mapping are all generated from this list.
  securityFields = [
    {
      name = "dropAllCapabilities";
      type = lib.types.bool;
      default = true;
      description = "OWASP Rule #3: Drop all Linux capabilities by default.";
      apply = v: lib.optionalAttrs v { dropCapabilities = lib.mkDefault [ "ALL" ]; };
    }
    {
      name = "noNewPrivileges";
      type = lib.types.bool;
      default = true;
      description = "OWASP Rule #4: Prevent in-container privilege escalation.";
      apply = v: lib.optionalAttrs v { noNewPrivileges = lib.mkDefault true; };
    }
    {
      name = "readOnlyRootFilesystem";
      type = lib.types.bool;
      default = true;
      description = "OWASP Rule #8: Set container root filesystem to read-only.";
      apply = v: lib.optionalAttrs v { readOnly = lib.mkDefault true; };
    }
    {
      name = "memoryLimit";
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "OWASP Rule #7: Limit container memory. null = no limit.";
      apply = v: lib.optionalAttrs (v != null) { memory = lib.mkDefault v; };
    }
    {
      name = "pidsLimit";
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "OWASP Rule #7: Limit number of processes. null = no limit.";
      apply = v: lib.optionalAttrs (v != null) { pidsLimit = lib.mkDefault v; };
    }
  ];

  enabledStacks = lib.filterAttrs (_: svc: svc.stack.enable) config.services.my;

  prefixName =
    stackName: containerCount: shortName:
    if containerCount == 1 then shortName else "${stackName}-${shortName}";
in
{
  options.services.my = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }:
        let
          stackCfg = config.stack;
          containerCount = builtins.length (lib.attrNames stackCfg.containers);
          memberServices = map (short: "${prefixName name containerCount short}.service") (
            lib.attrNames stackCfg.containers
          );
        in
        {
          options.stack = {
            enable = lib.mkEnableOption "stack infrastructure (directories, users, network, containers)";

            path = lib.mkOption {
              type = lib.types.str;
              default = "/etc/stacks/${name}";
              description = "Base path for the stack's data.";
            };

            directories = lib.mkOption {
              type = lib.types.listOf (
                lib.types.either lib.types.str (
                  lib.types.submodule {
                    options = {
                      path = lib.mkOption {
                        type = lib.types.str;
                        description = "Subdirectory name under the stack path.";
                      };
                      mode = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Permission mode. null = stack default (0750 with user, 0755 without).";
                      };
                      owner = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Owner. null = stack default (user name or root).";
                      };
                      group = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Group. null = stack default (user group or root).";
                      };
                    };
                  }
                )
              );
              default = [ ];
              description = "Subdirectories to create under the stack path. Strings use defaults, attrsets allow custom mode/owner/group.";
            };

            user = {
              enable = lib.mkEnableOption "system user and group for this stack";
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
              };
              uid = lib.mkOption {
                type = lib.types.nullOr lib.types.int;
                default = null;
              };
              group = lib.mkOption {
                type = lib.types.str;
                default = name;
              };
              gid = lib.mkOption {
                type = lib.types.nullOr lib.types.int;
                default = null;
              };
              extraGroups = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            };

            network = {
              enable = lib.mkEnableOption "dedicated bridge network for this stack";
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Network name, also used as interface name.";
              };
            };

            main = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Short name of the main container. Auto-publishes 127.0.0.1:<my.port>:<internalPort>.";
            };

            internalPort = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
              description = "Container-internal port of the main container.";
            };

            containers = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submoduleWith {
                  modules = containerModules ++ [
                    {
                      options = {
                        dependsOn = lib.mkOption {
                          type = lib.types.listOf lib.types.str;
                          default = [ ];
                          description = "Sibling short names. Auto-generates After and Requires with prefixed refs.";
                        };

                        security = lib.listToAttrs (
                          map (
                            field:
                            lib.nameValuePair field.name (
                              lib.mkOption {
                                type = lib.types.nullOr field.type;
                                default = null;
                                description = "Override ${field.name} for this container. null = use stack global.";
                              }
                            )
                          ) securityFields
                        );
                      };
                    }
                  ];
                }
              );
              default = { };
              description = "Containers in this stack. Short name keys get auto-prefixed with the stack name.";
            };

            security = {
              enable = lib.mkEnableOption "OWASP Docker security hardening for stack containers";
            }
            // lib.listToAttrs (
              map (
                field:
                lib.nameValuePair field.name (
                  lib.mkOption {
                    inherit (field) type default description;
                  }
                )
              ) securityFields
            );
          };

          config.backup = lib.mkIf stackCfg.enable {
            paths = lib.mkDefault [ stackCfg.path ];
            systemd.unit = lib.mkIf (stackCfg.containers != { }) (lib.mkDefault memberServices);
          };
        }
      )
    );
  };

  config = lib.mkMerge [
    {
      assertions = lib.concatLists (
        lib.mapAttrsToList (
          stackName: svc:
          let
            stackCfg = svc.stack;
            names = lib.attrNames stackCfg.containers;
            available = builtins.concatStringsSep ", " names;
          in
          lib.optionals stackCfg.enable (
            lib.optional (stackCfg.main != null && !(builtins.elem stackCfg.main names)) {
              assertion = false;
              message = "services.my.${stackName}.stack.main = \"${stackCfg.main}\" does not match any container (available: ${available}).";
            }
            ++ lib.concatLists (
              lib.mapAttrsToList (
                shortName: containerCfg:
                map (
                  dep:
                  lib.mkIf (!(builtins.elem dep names)) {
                    assertion = false;
                    message = "services.my.${stackName}.stack.containers.${shortName}.dependsOn contains \"${dep}\" which is not a sibling container (available: ${available}).";
                  }
                ) containerCfg.dependsOn
              ) stackCfg.containers
            )
          )
        ) enabledStacks
      );
    }

    {
      systemd.tmpfiles.rules = lib.mkMerge (
        lib.mapAttrsToList (
          _: svc:
          let
            stackCfg = svc.stack;
            defaultMode = if stackCfg.user.enable then "0750" else "0755";
            defaultOwner = if stackCfg.user.enable then stackCfg.user.name else "root";
            defaultGroup = if stackCfg.user.enable then stackCfg.user.group else "root";
            normalizeDir =
              entry:
              if builtins.isString entry then
                {
                  path = entry;
                  mode = defaultMode;
                  owner = defaultOwner;
                  group = defaultGroup;
                }
              else
                {
                  inherit (entry) path;
                  mode = if entry.mode != null then entry.mode else defaultMode;
                  owner = if entry.owner != null then entry.owner else defaultOwner;
                  group = if entry.group != null then entry.group else defaultGroup;
                };
          in
          lib.mkIf stackCfg.enable (
            map (
              entry:
              let
                dir = normalizeDir entry;
              in
              "d ${stackCfg.path}/${dir.path} ${dir.mode} ${dir.owner} ${dir.group}"
            ) stackCfg.directories
          )
        ) enabledStacks
      );
    }

    {
      users = lib.mkMerge (
        lib.mapAttrsToList (
          _: svc:
          let
            userCfg = svc.stack.user;
          in
          lib.mkIf (svc.stack.enable && userCfg.enable) {
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
          _: svc:
          let
            netCfg = svc.stack.network;
          in
          lib.mkIf (svc.stack.enable && netCfg.enable) {
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
            stackName: svc:
            let
              stackCfg = svc.stack;
              secCfg = stackCfg.security;
              containerCount = builtins.length (lib.attrNames stackCfg.containers);
            in
            lib.optionals stackCfg.enable (
              lib.mapAttrsToList (
                shortName: containerCfg:
                let
                  fullName = prefixName stackName containerCount shortName;

                  base = removeAttrs containerCfg [
                    "dependsOn"
                    "security"
                    # quadlet-nix internal/read-only attrs
                    "ref"
                    "_serviceName"
                    "_configText"
                    "_autoStart"
                    "_autoEscapeRequired"
                    "_rootless"
                    "_overrides"
                  ];

                  withNetwork =
                    if stackCfg.network.enable && base.containerConfig.networks == [ ] then
                      base
                      // {
                        containerConfig = base.containerConfig // {
                          networks = [ config.virtualisation.quadlet.networks.${stackCfg.network.name}.ref ];
                        };
                      }
                    else
                      base;

                  withPorts =
                    if
                      stackCfg.main == shortName
                      && stackCfg.internalPort != null
                      && withNetwork.containerConfig.publishPorts == [ ]
                    then
                      withNetwork
                      // {
                        containerConfig = withNetwork.containerConfig // {
                          publishPorts = [
                            "127.0.0.1:${toString svc.port}:${toString stackCfg.internalPort}"
                          ];
                        };
                      }
                    else
                      withNetwork;

                  depRefs = map (dep: "${prefixName stackName containerCount dep}.container") containerCfg.dependsOn;
                  withDeps =
                    if containerCfg.dependsOn != [ ] then
                      withPorts
                      // {
                        unitConfig = withPorts.unitConfig // {
                          After = (withPorts.unitConfig.After or [ ]) ++ depRefs;
                          Requires = (withPorts.unitConfig.Requires or [ ]) ++ depRefs;
                        };
                      }
                    else
                      withPorts;

                  securityAttrs = lib.foldl' (
                    acc: field:
                    let
                      effective =
                        if containerCfg.security.${field.name} != null then
                          containerCfg.security.${field.name}
                        else
                          secCfg.${field.name};
                    in
                    acc // field.apply effective
                  ) { } securityFields;
                  withSecurity =
                    if secCfg.enable then
                      withDeps
                      // {
                        containerConfig = withDeps.containerConfig // securityAttrs;
                      }
                    else
                      withDeps;
                in
                {
                  ${fullName} = withSecurity;
                }
              ) stackCfg.containers
            )
          ) enabledStacks
        )
      );
    }
  ];
}
