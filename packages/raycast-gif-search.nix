{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "5eeb9183af3baf68000a4ad9bd5e928c0ac6d8d6";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-RqlRNjbhzQ526x5+FJYhar9Edj6xtGeKiOq3Q3ncvOk=";
}
