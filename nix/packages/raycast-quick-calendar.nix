{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "ee4def5d2a6afb583bc96b52287c125fecf472ad";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "calendar";
  inherit rev;
  hash = "sha256-l18qeuZVeJmbJPWYSz+6N/hvsC7ibBKH/0GKakALVgw=";
}
