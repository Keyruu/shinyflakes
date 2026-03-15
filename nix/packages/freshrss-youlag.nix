{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=civilblur/youlag
  version = "v4.1.1";
in
pkgs.fetchFromGitHub {
  owner = "civilblur";
  repo = "youlag";
  rev = version;
  hash = "sha256-h0LN56NnbWiHUBbBLXvCV0cB1lJkpl1v6QL+U3qWQ+M=";
}
