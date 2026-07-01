{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "8e62185e9282b311e115f78973724dad6ea81b19";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-+YfIU7HcUg7amfQndPaZ9+iXJpwkSVpdlddhJxDkNwg=";
}
