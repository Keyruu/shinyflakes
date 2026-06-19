{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "cbf58a0306a2ee15dbc1385376db2ed8a6c979c3";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "calendar";
  inherit rev;
  hash = "sha256-dpyjXJE/Z/ZEUa7cTnpZxLluOpSJV5OFJTwrLhNeUJM=";
}
