{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "9a79f0f4f0ed27609bb43f63c9e68deae5bc414c";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-AtewnNow7ca7z4TwJyW0Mj5ZdYJiaIEQatbc22+9dG8=";
}
