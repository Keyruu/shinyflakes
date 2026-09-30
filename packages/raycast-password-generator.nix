{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "7705eb923c4fc5e012ea5d3de55b3ea87bacd91c";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-49CvREXw5jVsveZ1Qx75Lj7R6Xy3GmAc+Ma5125rPeI=";
}
