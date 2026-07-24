{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "f0795cc3855c697ce0d54f1be9f9e4992b88b957";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-AtewnNow7ca7z4TwJyW0Mj5ZdYJiaIEQatbc22+9dG8=";
}
