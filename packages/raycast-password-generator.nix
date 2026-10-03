{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "11b060ecbad725f70a91e077c7a4b65f640cb1f9";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-49CvREXw5jVsveZ1Qx75Lj7R6Xy3GmAc+Ma5125rPeI=";
}
