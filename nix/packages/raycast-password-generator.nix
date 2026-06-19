{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "cbf58a0306a2ee15dbc1385376db2ed8a6c979c3";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-cjj7dnfofn/pNQyJZHLYqTX307nFMDd+7hINe1wZ2jI=";
}
