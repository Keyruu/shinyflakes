{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "e654790081785bf9e8d2ff2e97eed3ca7b30938c";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-AtewnNow7ca7z4TwJyW0Mj5ZdYJiaIEQatbc22+9dG8=";
}
