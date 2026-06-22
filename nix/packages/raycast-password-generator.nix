{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "6411f14461ccbf98a89d6e946e4a0c0323ff5c71";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-cjj7dnfofn/pNQyJZHLYqTX307nFMDd+7hINe1wZ2jI=";
}
