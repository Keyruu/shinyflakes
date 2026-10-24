{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "1a0ef1d91a7d2b1ce55ee8cd2323d98bcfb1f5ac";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-49CvREXw5jVsveZ1Qx75Lj7R6Xy3GmAc+Ma5125rPeI=";
}
