{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=civilblur/youlag
  version = "v4.2.0";
in
pkgs.fetchFromGitHub {
  owner = "civilblur";
  repo = "youlag";
  rev = version;
  hash = "sha256-CmL7CBlZjD6qGTovCTvfn+um98gba5DPqtb/EVG/cR4=";
}
