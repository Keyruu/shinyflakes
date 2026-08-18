{ den, ... }:
let
  lucas = den.people.lucas;
in
{
  den.aspects.options.mesh.nixos = { host, lib, ... }: {
    options.services.mesh = with lib.types; {
      interface = lib.mkOption {
        type = str;
        default = "mesh0";
      };
      ip = lib.mkOption {
        type = str;
        default = lucas.devices.${host.hostName}.ip;
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
      zones = lib.mkOption {
        type = attrsOf (
          attrsOf (submodule {
            options = {
              ip = lib.mkOption { type = str; };
              publicKey = lib.mkOption { type = str; };
              allowedIPs = lib.mkOption {
                type = listOf str;
                default = [ ];
              };
            };
          })
        );
        default = { };
      };
    };
  };
}
