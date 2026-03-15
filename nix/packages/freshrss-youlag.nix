{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=civilblur/youlag
  version = "v4.1.0";
in
pkgs.fetchFromGitHub {
  owner = "civilblur";
  repo = "youlag";
  rev = version;
  hash = "sha256-qvrpEjQnZCj+9B1yT/tQLEts10nb+Xclxr3K2xZ966U=";
}
