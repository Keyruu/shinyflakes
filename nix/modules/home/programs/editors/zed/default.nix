{ inputs, pkgs, ... }:
let
  pkgs-stable = import inputs.nixpkgs-stable { inherit (pkgs.stdenv.hostPlatform) system; };
in
{
  imports = [
    ./settings.nix
    ./keymap.nix
    ./tasks.nix
  ];

  programs.zed-editor = {
    enable = true;
    package = pkgs-stable.zed-editor;
  };
}
