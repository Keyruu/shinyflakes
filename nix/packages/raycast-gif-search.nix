{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "9a79f0f4f0ed27609bb43f63c9e68deae5bc414c";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-neenXhjjQ5Xayt/SPqq+Y3kPytWgOMZmKPfSn6BJN84=";
}
