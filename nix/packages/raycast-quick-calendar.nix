{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "b39f8342d0a21b1ad9d9e4219b370aac57aa49c7";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "calendar";
  inherit rev;
  hash = "sha256-dpyjXJE/Z/ZEUa7cTnpZxLluOpSJV5OFJTwrLhNeUJM=";
}
