{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "b39f8342d0a21b1ad9d9e4219b370aac57aa49c7";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "password-generator";
  inherit rev;
  hash = "sha256-cjj7dnfofn/pNQyJZHLYqTX307nFMDd+7hINe1wZ2jI=";
}
