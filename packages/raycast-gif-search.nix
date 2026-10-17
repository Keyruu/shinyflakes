{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "e00070aa23e5ae2d90ffb7e02c6b1b569052856f";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-IS4Ax8YUaOpV2ovKyYibWWfDlGrd202Nwj7sbLbfHEs=";
}
