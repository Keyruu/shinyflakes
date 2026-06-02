{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "3f7bf4d8f11dda61d1da77ddd4c0e67eb997d099";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "calendar";
  inherit rev;
  hash = "sha256-AQkt6qM0U9nmqUtyirhHGGxwUs+25mjK5qlMuOjxV0A=";
}
