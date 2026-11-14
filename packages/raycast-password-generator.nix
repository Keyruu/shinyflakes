{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "28bf9eb29c72c2df9b4b1d17e3f7b51001de6c0d";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-JbGrGRA5YgYbiMKlMGE3N//OoeIlQ6WzCcqIKaYW/GY=";
}
