{ lib, ... }:
{
  options.services.my = lib.mkOption {
    type =
      with lib.types;
      attrsOf (submodule {
        options = {
          enable = lib.mkEnableOption "my service";
          port = lib.mkOption { type = with lib.types; either port (listOf port); };
          proto = lib.mkOption {
            type = lib.types.enum [
              "tcp"
              "udp"
              "both"
            ];
            default = "tcp";
          };
          domain = lib.mkOption { type = lib.types.str; };
          access = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ "lucas" ];
          };
        };
      });
    default = { };
  };
}
