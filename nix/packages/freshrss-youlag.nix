{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=civilblur/youlag
  version = "v4.4.0";
in
pkgs.fetchFromGitHub {
  owner = "civilblur";
  repo = "youlag";
  rev = version;
  hash = "sha256-M/YCY0tWqks6ozYMmdindinldwq61ViQfa2+MOPoPZU=";
}
