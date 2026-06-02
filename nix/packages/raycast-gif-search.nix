{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "3f7bf4d8f11dda61d1da77ddd4c0e67eb997d099";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-lKlsPvPXc2gRL2lJjrVc4/RWDXoWlRVNK6PMgQJ7TMs=";
}
