{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=civilblur/youlag
  version = "v4.3.0";
in
pkgs.fetchFromGitHub {
  owner = "civilblur";
  repo = "youlag";
  rev = version;
  hash = "sha256-nO+RElBKHHzySqZ/xoUfHVvlQGytVebkjci3NWtl/vY=";
}
