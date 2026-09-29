{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=yokoffing/Betterfox
  version = "116.1";
in
pkgs.fetchFromGitHub {
  owner = "yokoffing";
  repo = "Betterfox";
  rev = version;
  hash = "sha256-Ai8Szbrk/4FhGhS4r5gA2DqjALFRfQKo2a/TwWCIA6g=";
}