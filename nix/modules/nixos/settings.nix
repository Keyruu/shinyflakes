{ lib, ... }:
{
  options = {
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Primary user name";
      };
      font = lib.mkOption {
        type = lib.types.str;
        description = "Primary Font to use";
        default = "Maple Mono Normal NL NF";
      };
    };
  };
}
