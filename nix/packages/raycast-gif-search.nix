{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "171f87df10fca4558be46ac3e8527546533fee22";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-0zg7cbnlccWjOyL2Ulh5/gmRkQaHtYKcnwD7aBvMGS8=";
}
