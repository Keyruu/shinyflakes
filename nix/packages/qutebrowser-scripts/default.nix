{ pkgs, ... }:
let
  qute-profile = import ./qute-profile.nix { inherit pkgs; };
  qute-open = import ./qute-open.nix { inherit pkgs qute-profile; };
  qute-1pass = import ./qute-1pass.nix { inherit pkgs; };
  qute-vomnibar = import ./qute-vomnibar.nix { inherit pkgs; };
in
pkgs.symlinkJoin {
  name = "qutebrowser-scripts";
  paths = [ qute-profile qute-open qute-1pass qute-vomnibar ];
}
