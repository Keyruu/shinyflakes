{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "3f7bf4d8f11dda61d1da77ddd4c0e67eb997d099";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-VbC6h6TuvPlnPvVGs23pefw4a4musuZI+wTUg9v+9jk=";
}
