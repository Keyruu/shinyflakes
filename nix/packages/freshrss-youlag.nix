{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=civilblur/youlag
  version = "v4.4.1";
in
pkgs.fetchFromGitHub {
  owner = "civilblur";
  repo = "youlag";
  rev = version;
  hash = "sha256-/2BR7bKHh+a0PqWDbIM/TOcXoLznIx6UIcO6hMEM5rc=";
}
