{ inputs, pkgs, ... }:
let
  pkgs-small = import inputs.nixpkgs-small { inherit (pkgs) system; };
in
{
  imports = [
    ./settings.nix
    ./keymap.nix
    ./tasks.nix
  ];

  programs.zed-editor = {
    enable = true;
    package = pkgs-small.zed-editor;
  };
}
