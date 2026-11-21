{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "6630f77aee7136fd5ad46bf2288774536956e711";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-5yXpgID4MxRhAnzBb8GHVidn2LgBLcmVYvS07XDFBLc=";
}
