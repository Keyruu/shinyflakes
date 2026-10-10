{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "5eeb9183af3baf68000a4ad9bd5e928c0ac6d8d6";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-49CvREXw5jVsveZ1Qx75Lj7R6Xy3GmAc+Ma5125rPeI=";
}
