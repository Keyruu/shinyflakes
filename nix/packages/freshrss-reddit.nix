{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=aledeg/xExtension-RedditImage
  version = "v1.2.0";
in
pkgs.fetchFromGitHub {
  owner = "aledeg";
  repo = "xExtension-RedditImage";
  rev = version;
  hash = "sha256-H/uxt441ygLL0RoUdtTn9Q6Q/Ois8RHlhF8eLpTza4Q=";
}
