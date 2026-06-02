{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "f8ef33d45e11e4ed5fa65f8f8cc06a788a97b2dc";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-LwFrFNU8iyipMyn1wuPrm+oCiBBh/wIFE4yRoeTRarI=";
}
