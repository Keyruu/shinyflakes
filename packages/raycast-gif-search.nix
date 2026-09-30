{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "7705eb923c4fc5e012ea5d3de55b3ea87bacd91c";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-Cee+us06qvQqNUGoPwSq/qq+EEpROeFRP0eQGQbSslo=";
}
