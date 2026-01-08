{ lib, ... }:
{
  options.services.mesh.people = lib.mkOption {
    type =
      with lib.types;
      attrsOf (
        attrsOf (submodule {
          options = {
            ip = lib.mkOption { type = str; };
            publicKey = lib.mkOption { type = str; };
          };
        })
      );
    default = { };
  };

  config.services.mesh.people = {
    # simon = {
    # };
    # nadine = {
    # };
    lucas = {
      mentat = {
        ip = "100.67.0.2";
        publicKey = "nDCk5Y9nEaoV51hLDGCjzlRyglAx/UcH9v1W9F9/imw=";
      };
    };
  };
}
