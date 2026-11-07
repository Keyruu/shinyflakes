{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "ea0a44bb4197d4cbd6798b8e8bef8357d4420cde";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-YU+pIaRyvFzCuUQG9sOT5wipBaE9yl7+5enq0RSbXnM=";
}
