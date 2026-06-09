{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "ee4def5d2a6afb583bc96b52287c125fecf472ad";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-LwFrFNU8iyipMyn1wuPrm+oCiBBh/wIFE4yRoeTRarI=";
}
