{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "62382729217aed9f4403df896eab57a157fe5314";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-AtewnNow7ca7z4TwJyW0Mj5ZdYJiaIEQatbc22+9dG8=";
}
