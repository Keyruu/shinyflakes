{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "824eb135b0bbf26af269bbcf6500e70008b22eec";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "calendar";
  inherit rev;
  hash = "sha256-dpyjXJE/Z/ZEUa7cTnpZxLluOpSJV5OFJTwrLhNeUJM=";
}
