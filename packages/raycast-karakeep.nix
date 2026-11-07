{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "ea0a44bb4197d4cbd6798b8e8bef8357d4420cde";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "karakeep";
  inherit rev;
  hash = "sha256-Dr6ORTNsheQ9e4ANUufv+bFyzEAkGd/Ov4DyPHZVvQM=";
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
