{ pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "97f8181cf080bd18e9151ffbe423b7dfe21c3f10";
in
pkgs.callPackage ./_raycast-extension.nix { } {
  name = "password-generator";
  inherit rev;
  hash = "sha256-49CvREXw5jVsveZ1Qx75Lj7R6Xy3GmAc+Ma5125rPeI=";
  npmDepsHash = "sha256-ZuXJbesD5Ip24GERElGMCDZ/b3P7488+/or/XMnY91k=";
}
