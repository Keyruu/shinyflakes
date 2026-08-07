{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "62382729217aed9f4403df896eab57a157fe5314";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-neenXhjjQ5Xayt/SPqq+Y3kPytWgOMZmKPfSn6BJN84=";
}
