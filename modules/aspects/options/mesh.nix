{ ... }:
{
  den.aspects.mesh.nixos =
    { lib, ... }: {
      options.services.mesh = with lib.types; {
        interface = lib.mkOption {
          type = str;
          default = "mesh0";
        };
        ip = lib.mkOption {
          type = str;
        };
        subnet = lib.mkOption {
          type = str;
          default = "100.67.0.0/24";
        };
        networks = lib.mkOption {
          type = attrsOf str;
          default = { };
          example = {
            home = "192.168.100.0/24";
            nas = "192.168.100.7/32";
          };
          description = "Named networks that can be referenced in canAccess";
        };
        people = lib.mkOption {
          type = attrsOf (submodule {
            options = {
              canAccess = lib.mkOption {
                type = listOf str;
                default = [ ];
                description = "List of network names from services.mesh.networks";
              };

              devices = lib.mkOption {
                type = attrsOf (submodule {
                  options = {
                    ip = lib.mkOption {
                      type = str;
                    };
                    publicKey = lib.mkOption {
                      type = str;
                    };
                    allowedIPs = lib.mkOption {
                      type = listOf str;
                      default = [ ];
                    };
                  };
                });
                default = { };
              };
            };
          });
          default = { };
        };
        zones = lib.mkOption {
          type = attrsOf (attrsOf (submodule {
            options = {
              ip = lib.mkOption { type = str; };
              publicKey = lib.mkOption { type = str; };
              allowedIPs = lib.mkOption {
                type = listOf str;
                default = [ ];
              };
            };
          }));
          default = { };
        };
      };
    };
}