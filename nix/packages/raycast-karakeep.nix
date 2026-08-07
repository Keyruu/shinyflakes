{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "62382729217aed9f4403df896eab57a157fe5314";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "karakeep";
  inherit rev;
  hash = "sha256-dcraDAEa01+MwNSfZbsyQyto7EVzdyCXWTQSG71FFiQ=";
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
