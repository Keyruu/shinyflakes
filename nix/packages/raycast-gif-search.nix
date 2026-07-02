{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "22652506d7ba7ee0afa0c5b26e16966dbe0a434a";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "gif-search";
  inherit rev;
  hash = "sha256-+YfIU7HcUg7amfQndPaZ9+iXJpwkSVpdlddhJxDkNwg=";
}
