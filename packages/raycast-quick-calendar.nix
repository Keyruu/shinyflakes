{ pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "97f8181cf080bd18e9151ffbe423b7dfe21c3f10";
in
pkgs.callPackage ./_raycast-extension.nix { } {
  name = "calendar";
  inherit rev;
  hash = "sha256-qJ6/n4ZXlYF11kiCKddaJp6hHNbhdK6STrOY5rZT4Ck=";
  npmDepsHash = "sha256-FeVPsE9dl0YCNA0rQfHGsuzxZYz++AGZCCnWVxwq2pY=";
}
