{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=civilblur/youlag
  version = "v4.4.2";
in
pkgs.fetchFromGitHub {
  owner = "civilblur";
  repo = "youlag";
  rev = version;
  hash = "sha256-ET5KgLONRScdZDZQUESynxXIZHjU8f9hx8OqiKHGGaU=";
}
