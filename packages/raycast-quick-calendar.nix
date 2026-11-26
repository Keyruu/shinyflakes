{ pkgs, ... }:
let
  # renovate: datasource=git-refs depName=https://github.com/raycast/extensions branch=main
  rev = "7705eb923c4fc5e012ea5d3de55b3ea87bacd91c";
in
pkgs.callPackage ./_raycast-extension.nix { } {
  name = "calendar";
  inherit rev;
  hash = "sha256-SvPO1JSELqzdvI152KbPuNE+k29GIa3fp5MuF6sRKZI=";
  npmDepsHash = "sha256-sOAhwF++BxiVt6bCzXo2bWbg0NcDeOX2p0gz+FIbeIA=";
}
