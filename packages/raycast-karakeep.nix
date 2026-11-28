{ pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "97f8181cf080bd18e9151ffbe423b7dfe21c3f10";
in
pkgs.callPackage ./_raycast-extension.nix { } {
  name = "karakeep";
  inherit rev;
  hash = "sha256-boQR52q7RV9agCzs+c/K1rP5kcUzXRIev/pP+5hMgO8=";
  npmDepsHash = "sha256-rzZmx1Fa6Qyj6AKIClW6mscU1x/IenbAbGci2dOJwpo=";
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
