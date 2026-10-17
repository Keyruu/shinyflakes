{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "e00070aa23e5ae2d90ffb7e02c6b1b569052856f";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "calendar";
  inherit rev;
  hash = "sha256-SvPO1JSELqzdvI152KbPuNE+k29GIa3fp5MuF6sRKZI=";
}
