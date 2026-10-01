{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=yokoffing/Betterfox
  version = "154.0";
in
pkgs.fetchFromGitHub {
  owner = "yokoffing";
  repo = "Betterfox";
  rev = version;
  hash = "sha256-mIP/WcXUcGrJsWCJzR4zqPOmt0BbbpTZVaN/MbIwBbw=";
}
