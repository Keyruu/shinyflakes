{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "4a675ff62605e728d221a60208b9e88696f21dce";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-GEB0/hs+b0ePn8mGVMSglq2nWLlf04Kx4qZ0d9ZWmzc=";
}
