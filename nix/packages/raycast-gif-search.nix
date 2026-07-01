{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "96d10052a3f09bc96971a3a8d8421df3ec334f79";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-+YfIU7HcUg7amfQndPaZ9+iXJpwkSVpdlddhJxDkNwg=";
}
