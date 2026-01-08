{ lib, ... }:
{
  imports = [
    ./people.nix
    ./server.nix
  ];
  options.services.mesh = {
    interface = lib.mkOption {
      type = lib.types.str;
      default = "mesh0";
    };
  };
}
