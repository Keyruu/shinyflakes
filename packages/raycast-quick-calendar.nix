{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "6630f77aee7136fd5ad46bf2288774536956e711";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "calendar";
  inherit rev;
  hash = "sha256-qJ6/n4ZXlYF11kiCKddaJp6hHNbhdK6STrOY5rZT4Ck=";
}
