{ lib, ... }:
{
  options.services.my = lib.mkOption {
    type =
      with lib.types;
      attrsOf (submodule [
        (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "my service ${name}";

              port = lib.mkOption {
                type = either port (listOf port);
              };

              proto = lib.mkOption {
                type = enum [
                  "tcp"
                  "udp"
                  "both"
                ];
                default = "tcp";
              };

              domain = lib.mkOption {
                type = str;
              };
            };
          }
        )
        ./access.nix
      ]);
  };
}
