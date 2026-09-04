{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "e654790081785bf9e8d2ff2e97eed3ca7b30938c";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "calendar";
  inherit rev;
  hash = "sha256-xr2v2GwXEE1QJpe4OljcHYveBSiw69splSsCyT9gJIY=";
}
