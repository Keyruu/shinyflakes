{ lib, ... }:
{
  imports = [
    ./people.nix
    ./server.nix
  ];

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
  };
}
