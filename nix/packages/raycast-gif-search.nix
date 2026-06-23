{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "824eb135b0bbf26af269bbcf6500e70008b22eec";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-PJnGG/UyNTuzY96uuPljPIX8eHxEhETAvkXzT1cY3vE=";
}
