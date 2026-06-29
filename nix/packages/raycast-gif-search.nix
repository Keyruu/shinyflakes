{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "456d1919ef021d2a7dfd579378a09565e77e53af";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-EZa/oQ14xvgYkTBTR4nmCkAXYu4OVz7F4Sdfnl6EU/k=";
}
