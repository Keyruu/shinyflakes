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
            allowedIPs = lib.mkOption {
              type = listOf str;
              default = [ ];
            };
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
        allowedIPs = [ "192.168.100.0/24" ];
      };
      phone = {
        ip = "100.67.0.3";
        publicKey = "7FBclS8OV86p7IYYAKHnjm0dl+e9ImvMvh7+lLnOCyk=";
      };
    };
  };
}
