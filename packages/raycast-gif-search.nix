{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "4110beaf30c80b1d00345ee8f1e21221e77a4c63";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-neenXhjjQ5Xayt/SPqq+Y3kPytWgOMZmKPfSn6BJN84=";
}
