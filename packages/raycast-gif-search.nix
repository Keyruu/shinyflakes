{ pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "97f8181cf080bd18e9151ffbe423b7dfe21c3f10";
in
pkgs.callPackage ./_raycast-extension.nix { } {
  name = "gif-search";
  inherit rev;
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  npmDepsHash = "sha256-XbHI+2kn1I9e7Bz8AvRNrx51txaOHy2t5mdAYNdOb+0=";
}
