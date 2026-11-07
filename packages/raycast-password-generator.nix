{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "ea0a44bb4197d4cbd6798b8e8bef8357d4420cde";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-JbGrGRA5YgYbiMKlMGE3N//OoeIlQ6WzCcqIKaYW/GY=";
}
