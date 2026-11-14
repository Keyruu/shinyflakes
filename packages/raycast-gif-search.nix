{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "28bf9eb29c72c2df9b4b1d17e3f7b51001de6c0d";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-YU+pIaRyvFzCuUQG9sOT5wipBaE9yl7+5enq0RSbXnM=";
}
