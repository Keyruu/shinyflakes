{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "4a675ff62605e728d221a60208b9e88696f21dce";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "calendar";
  inherit rev;
  hash = "sha256-SvPO1JSELqzdvI152KbPuNE+k29GIa3fp5MuF6sRKZI=";
}
