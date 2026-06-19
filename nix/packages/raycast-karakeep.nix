{ inputs, pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "cbf58a0306a2ee15dbc1385376db2ed8a6c979c3";
in
inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension {
  name = "karakeep";
  inherit rev;
  hash = "sha256-0lSfbDvpvuIJv4Wc7Bk9fazElAKKDBx5Ws3FU7j2EXA=";
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
