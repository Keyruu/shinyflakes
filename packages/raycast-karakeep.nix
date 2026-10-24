{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "1a0ef1d91a7d2b1ce55ee8cd2323d98bcfb1f5ac";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "karakeep";
  inherit rev;
  hash = "sha256-H0/6rYCRKpNJ6KCGc/1y6Zp8JCvRKXzgCrSzCzHlSlY=";
  # karakeep's package.json overrides `ray build` with `-o dist`, so its
  # output ends up in ./dist instead of the default raycast extensions dir
  # that the upstream installPhase expects.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/* $out/
    runHook postInstall
  '';
}
