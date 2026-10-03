{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "11b060ecbad725f70a91e077c7a4b65f640cb1f9";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-RqlRNjbhzQ526x5+FJYhar9Edj6xtGeKiOq3Q3ncvOk=";
}
